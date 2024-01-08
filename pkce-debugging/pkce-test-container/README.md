#PKCE Tester
a simple docker container that helps with pkce debugging.

### Building
```
docker build -t dovholuknf/pkce-debugging .
```

### Example Usage
docker run \
	--rm \
	-p 8080:8080 \
	-eCLIENT_ID=pkcetest \
	-eAUTH_URL=https://keycloak.clint.demo.openziti.org:8446/realms/zitirealm/protocol/openid-connect/auth \
	-eTOKEN_URL=https://keycloak.clint.demo.openziti.org:8446/realms/zitirealm/protocol/openid-connect/token \
	dovholuknf/pkce-debugging
	
-- or HTTPS with LetsEncrypt --
docker run \
	--rm \
	-p 8080:8080 \
	-eCLIENT_ID=pkcetest \
	-eTLS_CERT=/etc/letsencrypt/live/clint.demo.openziti.org/fullchain.pem \
	-eTLS_KEY=/etc/letsencrypt/live/clint.demo.openziti.org/privkey.pem \
	-eAUTH_URL=https://keycloak.clint.demo.openziti.org:8446/realms/zitirealm/protocol/openid-connect/auth \
	-eTOKEN_URL=https://keycloak.clint.demo.openziti.org:8446/realms/zitirealm/protocol/openid-connect/token \
	-v/data/docker/letsencrypt:/etc/letsencrypt \
	dovholuknf/pkce-debugging

### Pushing to Dockerhub

```
docker tag dovholuknf/pkce-debugging:latest dovholuknf/pkce-debugging:latest
docker push dovholuknf/pkce-debugging:latest
```