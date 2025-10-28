# Quick Docker Example

run ../../fetch-zac.sh

## make sure zac path correct in compose file

docker compose up -d

# wait for it to come online....

ziti ops verify traffic --controller-url https://ec2-3-18-113-172.us-east-2.compute.amazonaws.com:8841/ --username admin --password discourse5255

## split/secure api

## exec to controller:
docker compose exec -it ziti-controller bash

# EDIT ${ZITI_CTRL_EDGE_NAME}.yaml or just run the commands below
# (or edit however you prefer)

```
sed '/^web/,$d' ${ZITI_NETWORK}.yaml > temp.yaml && \
  mv temp.yaml ${ZITI_NETWORK}.yaml

cat >> ${ZITI_NETWORK}.yaml <<HERE
web:
  - name: public-apis
    bindPoints:
      - interface: 0.0.0.0:8841
        address: ec2-3-18-113-172.us-east-2.compute.amazonaws.com:8841
    options:
      idleTimeout: 5000ms
      readTimeout: 5000ms
      writeTimeout: 100000ms
      minTLSVersion: TLS1.2
      maxTLSVersion: TLS1.3
    apis:
      - binding: edge-client
        options: { }
      - binding: edge-oidc
        options: { }
  - name: secured-apis
    bindPoints:
      - interface: ${ZITI_NETWORK}:${ZITI_CTRL_SECURE_PORT}
        address: ${ZITI_NETWORK}:${ZITI_CTRL_SECURE_PORT}
    options:
      idleTimeout: 5000ms
      readTimeout: 5000ms
      writeTimeout: 100000ms
      minTLSVersion: TLS1.2
      maxTLSVersion: TLS1.3
    apis:
      - binding: edge-management
        options: { }
      - binding: fabric
        options: { }
      - binding: zac
        options:
          location: /zac
          indexFile: index.html
HERE
```
---

docker compose restart ziti-controller

---

docker compose exec -it ziti-controller bash

ziti edge login ${ZITI_NETWORK}:$ZITI_CTRL_SECURE_PORT \
--username $ZITI_USER --password $ZITI_PWD --yes


ziti edge create config secure-apis-host.v1 host.v1 \
'{"protocol":"tcp", "address":"'"${ZITI_NETWORK}"'","port":'"${ZITI_CTRL_SECURE_PORT}"'}'
ziti edge create config secure-apis-intercept.v1 intercept.v1 \
'{"protocols":["tcp"],"addresses":["secured-apis.ziti"], "portRanges":[{"low":'${ZITI_CTRL_SECURE_PORT}', "high":'${ZITI_CTRL_SECURE_PORT}'}]}'
ziti edge create service secure-apis --configs "secure-apis-host.v1","secure-apis-intercept.v1" -a admin-services

ziti edge create service-policy "secured-apis-bind" Bind \
--service-roles "#admin-services" \
--identity-roles "@${ZITI_ROUTER_NAME}" \
--semantic "AnyOf"
ziti edge create service-policy "secured-apis-dial" Dial \
--service-roles "#admin-services" \
--identity-roles "#admins" \
--semantic "AnyOf"

ziti edge create identity ziti-admin -a admins -o ziti-admin.jwt

# now exit interactive container


---

docker compose cp ziti-controller:/persistent/ziti-admin.jwt .
scp cdaws:git/dovholuknf/openziti-scripts/discourse/5255/ziti-admin.jwt /mnt/c/temp/ziti-admin.jwt

# enroll identity

# go to 
https://secured-apis.ziti:8888/zac/dashboard








