function kcadm {
  docker compose \
    -f ${COMPOSE_FILE}.yml \
    --project-name ${PROJ_NAME} \
    exec -it keycloak \
    /opt/keycloak/bin/kcadm.sh $@;
}

kcadm config credentials \
  --server ${KEYCLOAK_NOSSL_URL} \
  --realm master \
  --user ${KEYCLOAK_ADMIN_USER} \
  --password ${KEYCLOAK_ADMIN_PWD}

kcadm create realms \
  -s realm=${KEYCLOAK_REALM} \
  -s enabled=true

kcadm create clients \
  -r ${KEYCLOAK_REALM} \
  -s clientId=${ZITI_BROWZER_CLIENT_ID} \
  -s protocol=openid-connect \
  -s 'redirectUris=["https://'"${ZITI_BROWZER_VHOST}"'/*","https://brozac.'"${WILDCARD_DNS}"'/*","https://docker-whale.'"${WILDCARD_DNS}"'/*"]' \
  -s 'webOrigins=["https://'"${ZITI_BROWZER_VHOST}"'","https://brozac.'"${WILDCARD_DNS}"'","https://docker-whale.'"${WILDCARD_DNS}"'"]' \
  -s 'directAccessGrantsEnabled=true'

CLIENT_SCOPE_ID=$(kcadm get clients -r ${KEYCLOAK_REALM} | jq -r '.[] | select(.clientId == "'${ZITI_BROWZER_CLIENT_ID}'") | .id')
kcadm update realms/${KEYCLOAK_REALM}/clients/${CLIENT_SCOPE_ID} --set fullScopeAllowed=false

kcadm create clients/${CLIENT_SCOPE_ID}/protocol-mappers/models \
  -r ${KEYCLOAK_REALM} \
  -s name=audience-mapping \
  -s protocol=openid-connect \
  -s protocolMapper=oidc-audience-mapper \
  -s config.\"included.custom.audience\"="${ZITI_BROWZER_CLIENT_ID}" \
  -s config.\"access.token.claim\"=\"true\" \
  -s config.\"id.token.claim\"=\"false\"


if [[ "${ZITI_BROWZER_GITHUB_CLIENTSECRET}" != "" ]]; then
  kcadm create identity-provider/instances \
    -r ${KEYCLOAK_REALM} \
    -s alias=github-oidc \
    -s providerId=github \
    -s enabled=true \
    -s 'config.useJwksUrl="true"' \
    -s config.clientId=${ZITI_BROWZER_GITHUB_CLIENT} \
    -s config.clientSecret=${ZITI_BROWZER_GITHUB_CLIENTSECRET}
fi

if [[ "${ZITI_BROWZER_GOOGLE_CLIENTSECRET}" != "" ]]; then
  kcadm create identity-provider/instances \
    -r ${KEYCLOAK_REALM} \
    -s alias=google-oidc \
    -s providerId=google \
    -s enabled=true \
    -s 'config.useJwksUrl="true"' \
    -s config.clientId=${ZITI_BROWZER_GOOGLE_CLIENT} \
    -s config.clientSecret=${ZITI_BROWZER_GOOGLE_CLIENTSECRET}
fi