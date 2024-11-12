echo "souring env file at $HOME/.ziti/quickstart/$(hostname)/$(hostname).env"
source $HOME/.ziti/quickstart/$(hostname)/$(hostname).env
ziti edge login -u $ZITI_USER -p $ZITI_PWD -y $ZITI_EDGE_CTRL_ADVERTISED_HOST_PORT

## cleanup steps.
export PATH=$PATH:$ZROK_ROOT/bin

echo "disabling services..."
sudo systemctl --timeout=10 disable nginx
sudo systemctl --timeout=10 disable zrok-frontend
sudo systemctl --timeout=10 disable zrok-controller
sudo systemctl --timeout=10 stop nginx
sudo systemctl --timeout=10 stop zrok-frontend
sudo systemctl --timeout=10 stop zrok-controller

echo "deleting from the openziti overlay..."

## zrok cleanup
if [[ -f "$HOME/.ziti/quickstart/$(hostname -s)/$(hostname -s).env" ]]; then
    source $HOME/.ziti/quickstart/$(hostname -s)/$(hostname -s).env
    #echo ziti edge login ctrl.${WILDCARD_DNS}:${ZITI_EDGE_CONTROLLER_PORT} -u $ZITI_USER -p $ZITI_PWD -y
    export ZITI_EDGE_CTRL_ADVERTISED_HOST_PORT=ctrl.${WILDCARD_DNS}:${ZITI_EDGE_CONTROLLER_PORT}
    ziti edge login ctrl.${WILDCARD_DNS}:${ZITI_EDGE_CONTROLLER_PORT} -u $ZITI_USER -p $ZITI_PWD -y
    ziti edge delete identity frontend
    ziti edge delete identity ctrl
fi

echo "removing the zrok folder at: $HOME/.zrok"
sudo rm -rf "$HOME/.zrok"

echo "cleanup complete..."  

sudo rm -rf /etc/systemd/system/zrok*
sudo systemctl daemon-reload
