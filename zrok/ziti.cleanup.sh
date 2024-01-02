sudo systemctl stop ziti-console
sudo systemctl stop ziti-router
sudo systemctl stop ziti-controller
sudo rm -rf $HOME/.ziti/quickstart
sudo systemctl disable ziti-console
sudo systemctl disable ziti-router
sudo systemctl disable ziti-controller
source /dev/stdin <<< "$(wget -qO- https://get.openziti.io/quick/ziti-cli-functions.sh)";

unsetZitiEnv

sudo rm -rf /etc/systemd/system/ziti-*
sudo systemctl daemon-reload

