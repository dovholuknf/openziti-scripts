SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $SCRIPT_DIR

echo "sourcing ziti-cli-functions.sh"
ZITI_CLI_FUNC="https://get.openziti.io/quick/ziti-cli-functions.sh"
#source /dev/stdin <<< "$(wget -qO- https://get.openziti.io/quick/ziti-cli-functions.sh)";
source /dev/stdin <<< "$(wget -qO- $ZITI_CLI_FUNC)";

unsetZitiEnv
source $SCRIPT_DIR/zrok.install.env

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

#diabled jan 2 echo "cloning ZAC"
#diabled jan 2 git clone https://github.com/openziti/ziti-console.git "${ZITI_HOME}/ziti-console"
#diabled jan 2 cd "${ZITI_HOME}/ziti-console"
#diabled jan 2 npm install
#diabled jan 2 #ln -s "${ZITI_PKI}/${ZITI_EDGE_CONTROLLER_HOSTNAME}-intermediate/certs/${ZITI_EDGE_CONTROLLER_HOSTNAME}-server.chain.pem" "${ZITI_HOME}/ziti-console/server.chain.pem"
#diabled jan 2 #ln -s "${ZITI_PKI}/${ZITI_EDGE_CONTROLLER_HOSTNAME}-intermediate/keys/${ZITI_EDGE_CONTROLLER_HOSTNAME}-server.key" "${ZITI_HOME}/ziti-console/server.key"
#diabled jan 2 ln -s "${LE_CHAIN}" "${ZITI_HOME}/ziti-console/server.chain.pem"
#diabled jan 2 ln -s "${LE_KEY}" "${ZITI_HOME}/ziti-console/server.key"

#sed -i 's#^      server_cert\: .*#      server_cert\: "'${LE_CHAIN}'"#g' $ZITI_HOME/$ZITI_NETWORK.yaml
#sed -i 's#^      key\:         .*#      key\:         "'${LE_KEY}'"#g' $ZITI_HOME/$ZITI_NETWORK.yaml

# cat /etc/letsencrypt/live/${ZROK_ZITI_CTRL_WILDCARD}/fullchain.pem >> $ZITI_HOME/pki/cas.pem
curl -s https://letsencrypt.org/certs/lets-encrypt-r3.pem >> $ZITI_HOME/pki/cas.pem
curl -s https://letsencrypt.org/certs/isrgrootx1.pem >> $ZITI_HOME/pki/cas.pem

sudo systemctl restart ziti-controller

#sed -i 's#\(^  ca\:.*\)#\1\n  alt_server_certs:\n    - server_cert\: "'${LE_CHAIN}'"\n      server_key\: "'${LE_KEY}'"#g' $ZITI_HOME/$ZITI_NETWORK-edge-router.yaml
sudo systemctl restart ziti-router


#diabled jan 2 createZacSystemdFile
#diabled jan 2 sudo cp "${ZITI_HOME}/ziti-console.service" /etc/systemd/system
#diabled jan 2 sudo systemctl daemon-reload
#diabled jan 2 sudo systemctl enable --now ziti-console
#sudo systemctl restart ziti-controller
#sudo systemctl restart ziti-router

