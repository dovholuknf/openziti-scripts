SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $SCRIPT_DIR

echo "sourcing ziti-cli-functions.sh"
ZITI_CLI_FUNC="https://raw.githubusercontent.com/openziti/ziti/fix-quickstart-again/quickstart/docker/image/ziti-cli-functions.sh"
ZITI_CLI_FUNC="https://get.openziti.io/quick/ziti-cli-functions.sh"
#source /dev/stdin <<< "$(wget -qO- https://get.openziti.io/quick/ziti-cli-functions.sh)";
source /dev/stdin <<< "$(wget -qO- $ZITI_CLI_FUNC)";

unsetZitiEnv
source $SCRIPT_DIR/zrok.install.env
source $SCRIPT_DIR/ziti.install.env

export EXTERNAL_IP="$(curl -s ipinfo.io | jq -r .ip)"
export ZITI_EDGE_CONTROLLER_IP_OVERRIDE="${EXTERNAL_IP}"
export ZITI_EDGE_ROUTER_IP_OVERRIDE="${EXTERNAL_IP}"
export ZITI_CTRL_EDGE_ADVERTISED_ADDRESS="${EXTERNAL_DNS}"
export ZITI_ROUTER_ADVERTISED_HOST="${EXTERNAL_DNS}"
export ZITI_CTRL_LISTENER_PORT=8440
export ZITI_CTRL_EDGE_ADVERTISED_PORT=8441
export ZITI_EDGE_ROUTER_PORT=8442
export ZITI_PKI_ALT_SERVER_CERT=/etc/letsencrypt/live/clint.demo.openziti.org/fullchain.pem
export ZITI_PKI_ALT_SERVER_KEY=/etc/letsencrypt/live/clint.demo.openziti.org/privkey.pem

echo "Running expressInstall"
expressInstall
createControllerSystemdFile 
createRouterSystemdFile "${ZITI_ROUTER_NAME}"

sudo cp "${ZITI_HOME}/${ZITI_NETWORK}.service" /etc/systemd/system/ziti-controller.service
sudo cp "${ZITI_HOME}/${ZITI_ROUTER_NAME}.service" /etc/systemd/system/ziti-router.service
sudo systemctl daemon-reload
sudo systemctl enable --now ziti-controller
sudo systemctl enable --now ziti-router
sudo systemctl -q status ziti-controller --lines=0 --no-pager
sudo systemctl -q status ziti-router --lines=0 --no-pager

echo "cloning ZAC"
git clone https://github.com/openziti/ziti-console.git "${ZITI_HOME}/ziti-console"
cd "${ZITI_HOME}/ziti-console"
npm install
#ln -s "${ZITI_PKI}/${ZITI_EDGE_CONTROLLER_HOSTNAME}-intermediate/certs/${ZITI_EDGE_CONTROLLER_HOSTNAME}-server.chain.pem" "${ZITI_HOME}/ziti-console/server.chain.pem"
#ln -s "${ZITI_PKI}/${ZITI_EDGE_CONTROLLER_HOSTNAME}-intermediate/keys/${ZITI_EDGE_CONTROLLER_HOSTNAME}-server.key" "${ZITI_HOME}/ziti-console/server.key"

ln -s "${LE_CHAIN}" "${ZITI_HOME}/ziti-console/server.chain.pem"
ln -s "${LE_KEY}" "${ZITI_HOME}/ziti-console/server.key"

#sed -i 's#^      server_cert\: .*#      server_cert\: "'${LE_CHAIN}'"#g' $ZITI_HOME/$ZITI_NETWORK.yaml
#sed -i 's#^      key\:         .*#      key\:         "'${LE_KEY}'"#g' $ZITI_HOME/$ZITI_NETWORK.yaml

# cat /etc/letsencrypt/live/${ZROK_ZITI_CTRL_WILDCARD}/fullchain.pem >> $ZITI_HOME/pki/cas.pem
curl -s https://letsencrypt.org/certs/lets-encrypt-r3.pem >> $ZITI_HOME/pki/cas.pem
curl -s https://letsencrypt.org/certs/isrgrootx1.pem >> $ZITI_HOME/pki/cas.pem

sudo systemctl restart ziti-controller

#sed -i 's#\(^  ca\:.*\)#\1\n  alt_server_certs:\n    - server_cert\: "'${LE_CHAIN}'"\n      server_key\: "'${LE_KEY}'"#g' $ZITI_HOME/$ZITI_NETWORK-edge-router.yaml
sudo systemctl restart ziti-router


createZacSystemdFile
sudo cp "${ZITI_HOME}/ziti-console.service" /etc/systemd/system
sudo systemctl daemon-reload
sudo systemctl enable --now ziti-console
#sudo systemctl restart ziti-controller
#sudo systemctl restart ziti-router

