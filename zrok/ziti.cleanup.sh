sudo systemctl --timeout=10 stop ziti-console
sudo systemctl --timeout=10 stop ziti-router
sudo systemctl --timeout=10 stop ziti-controller
sudo rm -rf $HOME/.ziti/quickstart
sudo systemctl --timeout=10 disable ziti-console
sudo systemctl --timeout=10 disable ziti-router
sudo systemctl --timeout=10 disable ziti-controller
source /dev/stdin <<< "$(wget -qO- https://get.openziti.io/quick/ziti-cli-functions.sh)";

unsetZitiEnv

sudo rm -rf /etc/systemd/system/ziti-*
sudo systemctl daemon-reload

