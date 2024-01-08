echo "souring env file at $HOME/.ziti/quickstart/$(hostname)/$(hostname).env"
source $HOME/.ziti/quickstart/$(hostname)/$(hostname).env
ziti edge login -u $ZITI_USER -p $ZITI_PWD -y $ZITI_EDGE_CTRL_ADVERTISED_HOST_PORT

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/ziti-zrok-browzer.env

ziti edge delete identity clint.dovholuk@netfoundry.io
ziti edge delete identity curt.tudor@netfoundry.io

ziti edge delete auth-policy browzer-keycloak-auth-policy
ziti edge delete external-jwt-signer browzer-keycloak-ext-jwt-signer

ziti edge delete service-policies where true
ziti edge delete services where true
ziti edge delete configs where true
