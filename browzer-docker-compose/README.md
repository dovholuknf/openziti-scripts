# BrowZer in Docker Compose 

This folder will get a full OpenZiti overlay and BrowZer all configured with self-signed certiifcates.

This is useful for dev work, or for controlling the CA/PKI directly.

## Getting it running

To bring up this environment do the following:
* clone this repo
* cd to `browzer-docker-compose`
* mkdir 'docker-data'
* `cp env-template .env`
* open the `.env` file and edit all the relevant settings
* after editing the `.env` file, source it: `source .env`
* generate the self-signed root CA and wildcard server keypair by running `./initialize-pki.sh`
* add the root ca to the appropriate trust store
* bring up the compose file: `docker compose up` (use -d if you want)
* configure keycloak by running: `./keycloak-configure.sh`
* configure the openziti overlay by running: `./openziti-configure.sh`
* OPTIONALLY: configure GitHub/Google (if using federated auth)

## Note
There are numerous hosts you'll need to make sure are in DNS or in your hosts file
or however you choose to make them resolvable:
* the router's alternate address, where the web socket listener is: `ZITI_BROWZER_WSS_ER_HOST`
* the controller's address: `ZITI_CTRL_EDGE_ADVERTISED_ADDRESS`
* the keycloak server address: `KEYCLOAK_BASE="keycloak.${WILDCARD_DNS}"`
* browzer's controller address: `ZITI_BROWZER_CONTROLLER_HOST` 
* etc. etc. etc. 