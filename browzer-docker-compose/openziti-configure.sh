function zer {
  docker compose \
    -f ${COMPOSE_FILE}.yml \
    --project-name ${PROJ_NAME} \
    exec -it ziti-edge-router "$@"
}

if zer grep -q "wss:" ziti-edge-router.yaml; then 
  echo "router config file appears to have web socket listener already: ziti-edge-router.yaml"
else
  # configuring the edge router for wss...
  echo "adding/replacing settings in the quickstart router. adding web socket listener, configuring ws block"
  zer sed -i 's#tproxy|host#tproxy|host'"\n"'  - binding: edge\n    address: wss:0.0.0.0:'${ZITI_BROWZER_WSS_ER_PORT}'\n    options:\n      advertise: '${ZITI_BROWZER_WSS_ER_HOST}':'${ZITI_BROWZER_WSS_ER_PORT}'\n      connectTimeoutMs: 5000\n      getSessionTimeout: 60#g' ziti-edge-router.yaml
  zer sed -i 's`#transport\:`transport\:`g' ziti-edge-router.yaml
  zer sed -i 's`#  ws\:`  ws\:`g' ziti-edge-router.yaml
  zer sed -i 's`#    `    `g' ziti-edge-router.yaml

  echo "restarting the ziti-router service"
  docker compose stop ziti-edge-router
  docker compose start ziti-edge-router
fi

# update trust in controller:
docker compose exec --user root ziti-controller update-ca-certificates

# need to bounce the controller to pick up new trust
docker compose stop ziti-controller
docker compose start ziti-controller

echo "waiting for keycloak to come online...."
wait_for_200="https://${ZITI_CTRL_EDGE_ADVERTISED_ADDRESS}:${ZITI_CTRL_EDGE_ADVERTISED_PORT:-1280}"
while [[ "$(curl -w "%{http_code}" -m 1 -s -k -o /dev/null "${wait_for_200}")" != "200" ]]; do
  echo "waiting for ${wait_for_200}"
  sleep 2
done
echo "${wait_for_200} responded with http 200"

function zitiDocker {
  docker compose \
    -f ${COMPOSE_FILE}.yml \
    --project-name ${PROJ_NAME} \
    exec -it ziti-controller \
    /var/openziti/ziti-bin/ziti "$@";
}

zitiDocker edge login localhost:1280 -u $ZITI_USER -p $ZITI_PWD -y

ziti_object_prefix=browzer-keycloak
issuer=$(curl -sk ${ZITI_BROWZER_OIDC_URL}/.well-known/openid-configuration | jq -r .issuer)
jwks=$(curl -sk ${ZITI_BROWZER_OIDC_URL}/.well-known/openid-configuration | jq -r .jwks_uri)

echo "OIDC issuer   : $issuer"
echo "OIDC jwks url : $jwks"

ext_jwt_signer=$(zitiDocker edge create ext-jwt-signer "${ziti_object_prefix}-ext-jwt-signer" "${issuer}" --jwks-endpoint "${jwks}" --audience "${ZITI_BROWZER_CLIENT_ID}" --claims-property email)
echo "ext jwt signer id: $ext_jwt_signer"

auth_policy=$(zitiDocker edge create auth-policy ${ziti_object_prefix}-auth-policy --primary-ext-jwt-allowed --primary-ext-jwt-allowed-signers ${ext_jwt_signer} --secondary-req-ext-jwt-signer ${ext_jwt_signer})
echo "auth policy id: $auth_policy"

echo "creating users specified by ZITI_BROWZER_IDENTITIES: ${ZITI_BROWZER_IDENTITIES}"
for id in ${ZITI_BROWZER_IDENTITIES}; do
  zitiDocker edge create identity user "${id}" --auth-policy ${auth_policy} --external-id "${id}" -a docker.whale.dialers,brozac.dialers
done

echo "adding router ziti-edge-router as docker.whale.binders"
zitiDocker edge update identity "ziti-edge-router" -a docker.whale.binders,brozac.binders,brozac.binders

wget -O- https://raw.githubusercontent.com/dovholuknf/openziti-scripts/main/ziti-zrok-browzer/docker.whale \
  | sed 's/ziti /zitiDocker /g' \
  | sed 's/offload_address=localhost/offload_address=docker-whale/g' \
  | sed 's/offload_port=2000/offload_port=8000/g' \
  > ./docker.whale
source ./docker.whale
createService

echo "-------------------- DONE --------------------"
echo ""
echo "now navigate to: https://docker-whale.${WILDCARD_DNS}"

if [[ "${zitadel_issuer}" != "" ]]; then
  ziti_object_prefix="zitadel"
  ext_jwt_signer=$(ziti edge create ext-jwt-signer "${ziti_object_prefix}-ext-jwt-signer" "${zitadel_issuer}" --jwks-endpoint "${zitadel_jwks}" --audience "${zitadel_client_id}" --claims-property email)
  echo "${ziti_object_prefix} ext jwt signer id: $ext_jwt_signer"

  auth_policy=$(ziti edge create auth-policy ${ziti_object_prefix}-auth-policy --primary-ext-jwt-allowed --primary-ext-jwt-allowed-signers ${ext_jwt_signer} --secondary-req-ext-jwt-signer ${ext_jwt_signer})
  echo "${ziti_object_prefix} auth policy id: $auth_policy"
fi

if [[ "${auth0_issuer}" != "" ]]; then
  ziti_object_prefix="auth0"
  ext_jwt_signer=$(ziti edge create ext-jwt-signer "${ziti_object_prefix}-ext-jwt-signer" "${auth0_issuer}" --jwks-endpoint "${auth0_jwks}" --audience "${auth0_client_id}" --claims-property email)
  echo "${ziti_object_prefix} ext jwt signer id: $ext_jwt_signer"

  auth_policy=$(ziti edge create auth-policy ${ziti_object_prefix}-auth-policy --primary-ext-jwt-allowed --primary-ext-jwt-allowed-signers ${ext_jwt_signer} --secondary-req-ext-jwt-signer ${ext_jwt_signer})
  echo "${ziti_object_prefix} auth policy id: $auth_policy"
fi