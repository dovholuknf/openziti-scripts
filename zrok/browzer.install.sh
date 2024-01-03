SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

source $SCRIPT_DIR/browzer.install.env
source $HOME/.ziti/quickstart/$(hostname)/$(hostname).env

echo "adding/replacing settings in the quickstart router. adding web socket listener, configuring ws block"
sed -i 's#tproxy|host#tproxy|host\n  - binding: edge\n    address: wss:0.0.0.0:'${ZITI_WSS_PORT}'\n    options:\n      advertise: '${ZITI_BROWZER_WSS_ER_HOST}':'${ZITI_WSS_PORT}'\n      connectTimeoutMs: 5000\n      getSessionTimeout: 60#g' $ZITI_HOME/$ZITI_NETWORK-edge-router.yaml
#sed -i 's#\(^.    key\:.*\)#\1\n    alt_server_certs:\n      - server_cert\: "'${LE_CHAIN}'"\n        server_key\: "'${LE_KEY}'"#g' $ZITI_HOME/$ZITI_NETWORK-edge-router.yaml
sed -i 's`#transport\:`transport\:`g' $ZITI_HOME/$ZITI_NETWORK-edge-router.yaml
sed -i 's`#  ws\:`  ws\:`g' $ZITI_HOME/$ZITI_NETWORK-edge-router.yaml
sed -i 's`#    `    `g' $ZITI_HOME/$ZITI_NETWORK-edge-router.yaml

echo "restarting the ziti-router service"
sudo systemctl restart ziti-router

echo "configuring OpenZiti for BrowZer..."
ziti_object_prefix=browzer-auth0
issuer=$(curl -s ${ZITI_BROWZER_OIDC_URL}/.well-known/openid-configuration | jq -r .issuer)
jwks=$(curl -s ${ZITI_BROWZER_OIDC_URL}/.well-known/openid-configuration | jq -r .jwks_uri)

echo "OIDC issuer   : $issuer"
echo "OIDC jwks url : $jwks"

echo "souring env file at $HOME/.ziti/quickstart/$(hostname)/$(hostname).env"
ziti edge login -u $ZITI_USER -p $ZITI_PWD -y $ZITI_EDGE_CTRL_ADVERTISED_HOST_PORT

ext_jwt_signer=$(ziti edge create ext-jwt-signer "${ziti_object_prefix}-ext-jwt-signer" "${issuer}" --jwks-endpoint "${jwks}" --audience "${ZITI_BROWZER_CLIENT_ID}" --claims-property email)
echo "ext jwt signer id: $ext_jwt_signer"

auth_policy=$(ziti edge create auth-policy ${ziti_object_prefix}-auth-policy --primary-ext-jwt-allowed --primary-ext-jwt-allowed-signers ${ext_jwt_signer})
echo "auth policy id: $auth_policy"

source $HOME/.ziti/quickstart/$(hostname)/$(hostname).env

echo "NOTE: copying letsencrypt certs to '$HOME/.browzer/pki'! IF these certs expire, you'll have to copy them here again!"
mkdir -p $HOME/.browzer/pki
sudo cp "/etc/letsencrypt/live/${ZITI_BROWZER_WILDCARD}/fullchain.pem" "$HOME/.browzer/pki/"
sudo cp "/etc/letsencrypt/live/${ZITI_BROWZER_WILDCARD}/privkey.pem" "$HOME/.browzer/pki/"
sudo chmod 777 $HOME/.browzer/pki/*
sudo chmod +x $HOME/.browzer/pki/*

cat > browzer-compose.yml <<HERE
version: "3.3"
services:
  browzer-bootstrapper:
    image: ghcr.io/openziti/ziti-browzer-bootstrapper:latest
    #restart: always

    volumes:
      - /usr/local/ziti/log:/home/node/ziti-http-agent/log
      - $HOME/.browzer/pki:/ziti

    ports:
      - "${ZITI_BROWZER_PORT}:443"

    environment:
      NODE_ENV: production
      ZITI_BROWZER_BOOTSTRAPPER_LOGLEVEL: debug
      ZITI_BROWZER_RUNTIME_LOGLEVEL: debug
      ZITI_CONTROLLER_HOST: ${ZITI_CTRL_EDGE_ADVERTISED_ADDRESS}
      ZITI_CONTROLLER_PORT: ${ZITI_CTRL_EDGE_ADVERTISED_PORT}
      ZITI_BROWZER_BOOTSTRAPPER_HOST: ${ZITI_BROWZER_HTTP_AGENT_URL}
      ZITI_BROWZER_BOOTSTRAPPER_LISTEN_PORT: ${ZITI_BROWZER_PORT}
      ZITI_BROWZER_BOOTSTRAPPER_CERTIFICATE_PATH: /ziti/fullchain.pem
      ZITI_BROWZER_BOOTSTRAPPER_KEY_PATH: /ziti/privkey.pem
      ZITI_BROWZER_BOOTSTRAPPER_SCHEME: https
      ZITI_BROWZER_BOOTSTRAPPER_TARGETS: >
          {
            "targetArray": [{
                       "vhost": "${ZITI_BROWZER_VHOST}",
                       "service": "${ZITI_BROWZER_SERVICE}",
                       "path": "/",
                       "scheme": "http",
                       "idp_issuer_base_url": "${ZITI_BROWZER_OIDC_URL}",
                       "idp_client_id": "${ZITI_BROWZER_CLIENT_ID}"
            }]
          }
HERE

echo "creating users specified by ZITI_BROWZER_IDENTITIES: ${ZITI_BROWZER_IDENTITIES}"
for id in ${ZITI_BROWZER_IDENTITIES}; do
  ziti edge create identity user "${id}" --auth-policy ${auth_policy} --external-id "${id}" -a docker.whale.dialers
done
