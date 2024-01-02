echo "setting variables..."
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

source $SCRIPT_DIR/zrok.install.env

## cleanup steps
export PATH=$PATH:$ZROK_ROOT/bin

echo "disabling services..."
sudo systemctl disable nginx
sudo systemctl disable zrok-frontend
sudo systemctl disable zrok-controller
sudo systemctl stop nginx
sudo systemctl stop zrok-frontend
sudo systemctl stop zrok-controller

echo "deleting from the openziti overlay..."

## zrok cleanup
if [[ -f "$HOME/.ziti/quickstart/$(hostname -s)/$(hostname -s).env" ]]; then
    source $HOME/.ziti/quickstart/$(hostname -s)/$(hostname -s).env
    #echo ziti edge login ctrl.${ZROK_ZITI_CTRL_WILDCARD}:${ZITI_EDGE_CONTROLLER_PORT} -u $ZITI_USER -p $ZITI_PWD -y
    export ZITI_EDGE_CTRL_ADVERTISED_HOST_PORT=ctrl.${ZROK_ZITI_CTRL_WILDCARD}:${ZITI_EDGE_CONTROLLER_PORT}
    ziti edge login ctrl.${ZROK_ZITI_CTRL_WILDCARD}:${ZITI_EDGE_CONTROLLER_PORT} -u $ZITI_USER -p $ZITI_PWD -y
    ziti edge delete identity frontend
    ziti edge delete identity ctrl
fi

echo "removing the zrok folder at: $HOME/.zrok"
sudo rm -rf "$HOME/.zrok"

echo "cleanup complete..."  

sudo rm -rf /etc/systemd/system/zrok*
sudo systemctl daemon-reload
