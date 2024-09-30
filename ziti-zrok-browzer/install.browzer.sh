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
if [[ "${ZITI_BROWZER_PORT}" != "" && "${ZITI_BROWZER_PORT}" != "443" ]]; then
  _ZITI_BROWZER_PORT=":${ZITI_BROWZER_PORT-}"
fi
cat > $SCRIPT_DIR/${ZITI_BROWZER_DOCKER_PROJECT}.yml <<HERE
services:
  browzer-keycloak:
    image: quay.io/keycloak/keycloak:${KEYCLOAK_VERSION}
    restart: always
    user: root

    volumes:
      - /data/docker/letsencrypt:/etc/letsencrypt
      - browzer-keycloak-data:/opt/keycloak/data
      - /data/docker/keycloak/themes/mytheme:/opt/keycloak/themes/mytheme
    
    ports:
      - "${KEYCLOAK_PORT}:${KEYCLOAK_PORT}"
    
    environment:
      - KEYCLOAK_ADMIN=\${KEYCLOAK_ADMIN_USER}
      - KEYCLOAK_ADMIN_PASSWORD=\${KEYCLOAK_ADMIN_PWD}
    
    command:
      - "start"
      - "--https-certificate-file=/etc/letsencrypt/live/${WILDCARD_DNS}/fullchain.pem"
      - "--https-certificate-key-file=/etc/letsencrypt/live/${WILDCARD_DNS}/privkey.pem"
      - "--hostname=${KEYCLOAK_BASE}"
      - "--https-port=${KEYCLOAK_PORT}"

  browzer-bootstrapper:
    image: ghcr.io/openziti/ziti-browzer-bootstrapper:${ZITI_BROWZER_VERSION:-latest}
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
      ZITI_BROWZER_RUNTIME_ORIGIN_TRIAL_TOKEN: "${ZITI_BROWZER_GOOGLE_JSPI_TOKEN}"
      _ZITI_BROWZER_BOOTSTRAPPER_WILDCARD_VHOSTS: false
      ZITI_BROWZER_BOOTSTRAPPER_TARGETS: >
          {
            "targetArray": [
            {
                      "vhost": "${ZITI_BROWZER_VHOST}${_ZITI_BROWZER_PORT}",
                      "service": "${ZITI_BROWZER_SERVICE}",
                      "path": "/",
                      "scheme": "http",
                      "idp_issuer_base_url": "${KEYCLOAK_HOST_AND_PORT}realms/zitirealm",
                      "idp_client_id": "${ZITI_BROWZER_CLIENT_ID}",
                      "idp_type": "keycloak",
                      "idp_realm": "${KEYCLOAK_REALM}"
            },
            {
                      "vhost": "brozac.${WILDCARD_DNS}${_ZITI_BROWZER_PORT}",
                      "service": "brozac",
                      "path": "/",
                      "scheme": "http",
                      "idp_issuer_base_url": "${KEYCLOAK_HOST_AND_PORT}realms/zitirealm",
                      "idp_client_id": "${ZITI_BROWZER_CLIENT_ID}",
                      "idp_type": "keycloak",
                      "idp_realm": "${KEYCLOAK_REALM}"
            },
            {
                      "vhost": "puter.clint.demo.openziti.org",
                      "service": "puter",
                      "path": "/",
                      "scheme": "http",
                      "idp_issuer_base_url": "${KEYCLOAK_HOST_AND_PORT}realms/zitirealm",
                      "idp_client_id": "${ZITI_BROWZER_CLIENT_ID}",
                      "idp_type": "keycloak",
                      "idp_realm": "${KEYCLOAK_REALM}"
            }
            ]
          }

  docker-whale:
    image: crccheck/hello-world
    ports:
      - "2000:8000"

  puter:
    image: ghcr.io/heyputer/puter:latest
    restart: unless-stopped
    ports:
      - '4100:4100'
    environment:
      # TZ: Europe/Paris
      # CONFIG_PATH: /etc/puter
      PUID: 1000
      PGID: 1000
    volumes:
      - /home/ubuntu/puter/config:/etc/puter
      - /home/ubuntu/puter/data:/var/puter
    healthcheck:
      test: wget --no-verbose --tries=1 --spider http://puter.localhost:4100/test || exit 1
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 30s

volumes:
  browzer-keycloak-data:
  browzer-ziti-fs:
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

wait_for_response="https://${KEYCLOAK_BASE}:${KEYCLOAK_PORT}"
while true; do
  http_code=$(curl -w "%{http_code}" -m 1 -s -k -o /dev/null "${wait_for_response}")
  if [[ $http_code -ge 200 && $http_code -le 350 ]]; then
    echo "Response code ${http_code} received, exiting loop."
    break
  fi
  echo "waiting for ${wait_for_response}, current code: ${http_code}"
  sleep 5
done

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

auth_policy=$(ziti edge create auth-policy ${ziti_object_prefix}-auth-policy --primary-ext-jwt-allowed --primary-ext-jwt-allowed-signers ${ext_jwt_signer} --secondary-req-ext-jwt-signer ${ext_jwt_signer})
echo "auth policy id: $auth_policy"

echo "creating users specified by ZITI_BROWZER_IDENTITIES: ${ZITI_BROWZER_IDENTITIES}"
for id in ${ZITI_BROWZER_IDENTITIES}; do
  ziti edge create identity "${id}" --auth-policy ${auth_policy} --external-id "${id}" -a docker.whale.dialers,brozac.dialers,puter.dialers
done


echo "adding router $(hostname)-edge-router as docker.whale.binders"
ziti edge update identity "$(hostname)-edge-router" -a docker.whale.binders,brozac.binders,brozac.binders

source $SCRIPT_DIR/docker.whale
createService

source $SCRIPT_DIR/brozac
createService

source $SCRIPT_DIR/puter.svc
createService
