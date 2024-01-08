#PKCE Tester
a simple docker container that helps with pkce debugging.

### Example Usage
docker run \
	--rm \
	-p 8080:8080 \
	-eCLIENT_ID=pkcetest \
	-eAUTH_URL=https://keycloak.clint.demo.openziti.org:8446/realms/zitirealm/protocol/openid-connect/auth \
	-eTOKEN_URL=https://keycloak.clint.demo.openziti.org:8446/realms/zitirealm/protocol/openid-connect/token \
	openziti/pkce-debugging