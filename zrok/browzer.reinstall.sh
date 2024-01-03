SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

source $HOME/.ziti/quickstart/$(hostname -s)/$(hostname -s).env
source $SCRIPT_DIR/browzer.install.env
source $SCRIPT_DIR/zrok.install.env

./browzer.cleanup.sh

./zrok.reinstall.sh

./browzer.install.sh

echo ""
echo ""
echo "souring env file at $HOME/.ziti/quickstart/$(hostname)/$(hostname).env"
ziti edge login -u $ZITI_USER -p $ZITI_PWD -y $ZITI_EDGE_CTRL_ADVERTISED_HOST_PORT

echo "creating docker whale service..."
source docker.whale
createService

echo "adding router to binding identities for docker whale"
ziti edge update identity "$(hostname)-edge-router" -a docker.whale.binders

docker compose -f browzer-compose.yml pull
docker compose -f browzer-compose.yml up -d
docker compose -f browzer-compose.yml logs
