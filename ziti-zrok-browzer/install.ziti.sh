echo "sourcing ziti-cli-functions.sh"
ZITI_CLI_FUNC="https://get.openziti.io/quick/ziti-cli-functions.sh"
source /dev/stdin <<< "$(wget -qO- $ZITI_CLI_FUNC)";
unsetZitiEnv
source $ENV_VAR_FILE

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

curl -s https://letsencrypt.org/certs/lets-encrypt-r3.pem >> $ZITI_HOME/pki/cas.pem
curl -s https://letsencrypt.org/certs/isrgrootx1.pem >> $ZITI_HOME/pki/cas.pem


rm -rf $ZITI_HOME/zacs/v${ZAC_VERSION}
mkdir -p $ZITI_HOME/zacs
wget -O $ZITI_HOME/zacs/v${ZAC_VERSION}-download.zip https://github.com/openziti/ziti-console/releases/download/app-ziti-console-v${ZAC_VERSION}/ziti-console.zip
unzip $ZITI_HOME/zacs/v${ZAC_VERSION}-download.zip -d $ZITI_HOME/zacs/v${ZAC_VERSION}

sed -i 's/#      - binding/      - binding/g' $ZITI_HOME/$(hostname).yaml
sed -i 's/#        options/        options/g' $ZITI_HOME/$(hostname).yaml
sed -i 's#"location": "./zac"#"location": "'$ZITI_HOME/zacs/v${ZAC_VERSION}'"#g' $ZITI_HOME/$(hostname).yaml

sudo systemctl restart ziti-controller
sudo systemctl restart ziti-router