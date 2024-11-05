unset EXTERNAL_DNS
base_dns=".clint.demo.openziti.org"
export ZITI_HOME="$(PWD)"
export EXTERNAL_IP="$(curl -s eth0.me)"       
export ZITI_CTRL_EDGE_IP_OVERRIDE="${EXTERNAL_IP}"
export ZITI_ROUTER_IP_OVERRIDE="${EXTERNAL_IP}"
export ZITI_CTRL_ADVERTISED_ADDRESS="hapctrl.${base_dns}"
export ZITI_CTRL_EDGE_ADVERTISED_ADDRESS="hapctrl."${base_dns}
export ZITI_ROUTER_ADVERTISED_ADDRESS="haper.${base_dns}"
export ZITI_CTRL_ADVERTISED_PORT=10443
export ZITI_CTRL_EDGE_ADVERTISED_PORT=10443
export ZITI_ROUTER_PORT=11443
read -sp "Enter ZITI_PWD: " ZITI_PWD && export ZITI_PWD
echo
source /dev/stdin <<< "$(wget -qO- https://get.openziti.io/ziti-cli-functions.sh)"; expressInstall


