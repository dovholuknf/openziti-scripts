echo "souring env file at $HOME/.ziti/quickstart/$(hostname)/$(hostname).env"
source $ENV_VAR_FILE
source $HOME/.ziti/quickstart/$(hostname)/$(hostname).env
ziti edge login -u $ZITI_USER -p $ZITI_PWD -y $ZITI_EDGE_CTRL_ADVERTISED_HOST_PORT

if grep -q "wss:" $HOME/.ziti/quickstart/$(hostname)/$(hostname)-edge-router.yaml; then 
  echo "router config file appears to have web socket listener already: $HOME/.ziti/quickstart/$(hostname)/$(hostname)-edge-router.yaml"
else
  echo "adding/replacing settings in the quickstart router. adding web socket listener, configuring ws block"
  sed -i 's#tproxy|host#tproxy|host\n  - binding: edge\n    address: wss:0.0.0.0:'${ZITI_BROWZER_WSS_ER_PORT}'\n    options:\n      advertise: '${ZITI_BROWZER_WSS_ER_HOST}':'${ZITI_BROWZER_WSS_ER_PORT}'\n      connectTimeoutMs: 5000\n      getSessionTimeout: 60#g' $ZITI_HOME/$ZITI_NETWORK-edge-router.yaml
  sed -i 's`#transport\:`transport\:`g' $ZITI_HOME/$ZITI_NETWORK-edge-router.yaml
  sed -i 's`#  ws\:`  ws\:`g' $ZITI_HOME/$ZITI_NETWORK-edge-router.yaml
  sed -i 's`#    `    `g' $ZITI_HOME/$ZITI_NETWORK-edge-router.yaml

  echo "restarting the ziti-router service"
  sudo systemctl restart ziti-router
fi

echo "make sure important keycloak directories exist and are writable:"
echo "  - /data/docker/keycloak/data"
echo "  - /data/docker/keycloak/themes"

function generateBrowzerComposeFile() {
cat > $SCRIPT_DIR/browzer-compose.yml <<HERE
version: "3.3"
services:
  browzer-keycloak:
    image: quay.io/keycloak/keycloak:23.0.1
    restart: always
    user: root

    volumes:
      - /data/docker/letsencrypt:/etc/letsencrypt
      - browzer-keycloak-data:/opt/keycloak/data
      - /data/docker/keycloak/themes/mytheme:/opt/keycloak/themes/mytheme
    
    ports:
      - "${KEYCLOAK_PORT}:${KEYCLOAK_PORT}"
    
    environment:
      - KEYCLOAK_ADMIN=${KEYCLOAK_ADMIN_USER}
      - KEYCLOAK_ADMIN_PASSWORD=${KEYCLOAK_ADMIN_PWD}
    
    command:
      - "start"
      - "--https-certificate-file=${LE_CHAIN}"
      - "--https-certificate-key-file=${LE_KEY}"
      - "--hostname=${KEYCLOAK_BASE}"
      - "--https-port=${KEYCLOAK_PORT}"

  browzer-bootstrapper:
    image: ghcr.io/openziti/ziti-browzer-bootstrapper:latest
    restart: always

    volumes:
      - /usr/local/ziti/log:/home/node/ziti-http-agent/log
      - /data/docker/letsencrypt:/etc/letsencrypt
      - $HOME/.browzer/pki:/ziti

    ports:
      - "${ZITI_BROWZER_PORT}:443"

    environment:
      NODE_ENV: production
      ZITI_BROWZER_BOOTSTRAPPER_LOGLEVEL: debug
      ZITI_BROWZER_RUNTIME_LOGLEVEL: debug
      ZITI_CONTROLLER_HOST: ctrl.${WILDCARD_DNS}
      ZITI_CONTROLLER_PORT: ${ZITI_CTRL_EDGE_ADVERTISED_PORT}
      ZITI_BROWZER_BOOTSTRAPPER_HOST: ${ZITI_BROWZER_HTTP_AGENT_URL}
      ZITI_BROWZER_BOOTSTRAPPER_LISTEN_PORT: ${ZITI_BROWZER_PORT}
      ZITI_BROWZER_BOOTSTRAPPER_CERTIFICATE_PATH: /etc/letsencrypt/live/${WILDCARD_DNS}/fullchain.pem
      ZITI_BROWZER_BOOTSTRAPPER_KEY_PATH: /etc/letsencrypt/live/${WILDCARD_DNS}/privkey.pem
      ZITI_BROWZER_BOOTSTRAPPER_SCHEME: https
      ZITI_BROWZER_BOOTSTRAPPER_TARGETS: >
          {
            "targetArray": [{
                       "vhost": "${ZITI_BROWZER_VHOST}",
                       "service": "${ZITI_BROWZER_SERVICE}",
                       "path": "/",
                       "scheme": "http",
                       "idp_issuer_base_url": "${ZITI_BROWZER_OIDC_ADDRESS}",
                       "idp_client_id": "${ZITI_BROWZER_CLIENT_ID}",
                       "idp_type": "keycloak",
                       "idp_realm": "${KEYCLOAK_REALM}"
            }]
          }

  docker-whale:
    image: crccheck/hello-world
    ports:
        - "2000:8000"
volumes:
  browzer-keycloak-data:
HERE
echo "wrote docker compose file for browzer to $SCRIPT_DIR/browzer-compose.yml"
}
generateBrowzerComposeFile

echo "using docker compose to pull, down, then up the ENTIRE ENVIRONMENT"
echo "*******************************************"
echo "** NEW ENVIRONMENT BEING PROVISIONED NOW **"
echo "*******************************************"
echo " "
docker compose -f $SCRIPT_DIR/${ZITI_BROWZER_DOCKER_PROJECT}.yml --project-name ${ZITI_BROWZER_DOCKER_PROJECT} pull
docker compose -f $SCRIPT_DIR/${ZITI_BROWZER_DOCKER_PROJECT}.yml --project-name ${ZITI_BROWZER_DOCKER_PROJECT} down -v
docker compose -f $SCRIPT_DIR/${ZITI_BROWZER_DOCKER_PROJECT}.yml --project-name ${ZITI_BROWZER_DOCKER_PROJECT} up -d

echo "waiting for keycloak to come online...."
wait_for_200="https://keycloak.clint.demo.openziti.org:8446"
while [[ "$(curl -w "%{http_code}" -m 1 -s -k -o /dev/null "${wait_for_200}")" != "200" ]]; do
  echo "waiting for ${wait_for_200}"
  sleep 5
done
echo "${wait_for_200} responded with http 200"
sleep 1

echo "configuring keycloak for OpenZiti and Browzer"
$SCRIPT_DIR/browzer.configure.keycloak.sh

echo "configuring OpenZiti for BrowZer..."
ziti_object_prefix=browzer-keycloak
issuer=$(curl -s ${ZITI_BROWZER_OIDC_URL}/.well-known/openid-configuration | jq -r .issuer)
jwks=$(curl -s ${ZITI_BROWZER_OIDC_URL}/.well-known/openid-configuration | jq -r .jwks_uri)

echo "OIDC issuer   : $issuer"
echo "OIDC jwks url : $jwks"

ext_jwt_signer=$(ziti edge create ext-jwt-signer "${ziti_object_prefix}-ext-jwt-signer" "${issuer}" --jwks-endpoint "${jwks}" --audience "${ZITI_BROWZER_CLIENT_ID}" --claims-property email)
echo "ext jwt signer id: $ext_jwt_signer"

auth_policy=$(ziti edge create auth-policy ${ziti_object_prefix}-auth-policy --primary-ext-jwt-allowed --primary-ext-jwt-allowed-signers ${ext_jwt_signer})
echo "auth policy id: $auth_policy"

echo "creating users specified by ZITI_BROWZER_IDENTITIES: ${ZITI_BROWZER_IDENTITIES}"
for id in ${ZITI_BROWZER_IDENTITIES}; do
  ziti edge create identity user "${id}" --auth-policy ${auth_policy} --external-id "${id}" -a docker.whale.dialers
done

echo "adding router $(hostname)-edge-router as docker.whale.binders"
ziti edge update identity "$(hostname)-edge-router" -a docker.whale.binders

source $SCRIPT_DIR/docker.whale

createService