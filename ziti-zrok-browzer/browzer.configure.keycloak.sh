function kcadm {  docker compose -f ${SCRIPT_DIR}/browzer-compose.yml exec -it browzer-keycloak /opt/keycloak/bin/kcadm.sh $@; }

kcadm config credentials \
  --server ${ZITI_BROWZER_OIDC_ADDRESS} \
  --realm master \
  --user ${KEYCLOAK_ADMIN_USER} \
  --password ${KEYCLOAK_ADMIN_PWD}

kcadm create realms \
  -s realm=${KEYCLOAK_REALM} \
  -s enabled=true

kcadm create identity-provider/instances \
  -r ${KEYCLOAK_REALM} \
  -s alias=github-oidc \
  -s providerId=github \
  -s enabled=true \
  -s 'config.useJwksUrl="true"' \
  -s 'config.authorizationUrl=https://github.com/login/oauth/authorize' \
  -s 'config.tokenUrl=https://github.com/login/oauth/access_token' \
  -s 'config.userInfoUrl=https://api.github.com/user' \
  -s config.clientId=${ZITI_BROWZER_GITHUB_CLIENT} \
  -s config.clientSecret=${ZITI_BROWZER_GITHUB_CLIENTSECRET}

kcadm create clients \
  -r ${KEYCLOAK_REALM} \
  -s clientId=${ZITI_BROWZER_CLIENT_ID} \
  -s protocol=openid-connect \
  -s 'redirectUris=["https://'${ZITI_BROWZER_VHOST}'/*"]' \
  -s 'directAccessGrantsEnabled=true'

CLIENT_SCOPE_ID=$(kcadm get clients -r ${KEYCLOAK_REALM} | jq -r '.[] | select(.clientId == "'${ZITI_BROWZER_CLIENT_ID}'") | .id')
kcadm update realms/${KEYCLOAK_REALM}/clients/${CLIENT_SCOPE_ID} --set fullScopeAllowed=false

#kcadm create client-scopes \
#  -r ${KEYCLOAK_REALM} \
#  -s name=browZerDemoScope \
#  -s 'protocol=openid-connect'

kcadm create clients/${CLIENT_SCOPE_ID}/protocol-mappers/models \
  -r ${KEYCLOAK_REALM} \
  -s name=audience-mapping \
  -s protocol=openid-connect \
  -s protocolMapper=oidc-audience-mapper \
  -s config.\"included.client.audience\"="${ZITI_BROWZER_CLIENT_ID}" \
  -s config.\"access.token.claim\"=\"true\" \
  -s config.\"id.token.claim\"=\"false\"