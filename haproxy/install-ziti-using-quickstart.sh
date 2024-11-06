unset EXTERNAL_DNS
source /dev/stdin <<< "$(wget -qO- https://get.openziti.io/ziti-cli-functions.sh)"
unsetZitiEnv
base_dns="clint.demo.openziti.org"
ha_proxy_port=5443
controller_port=10443
router_port=11443

export ZITI_HOME="$(pwd)/ziti"
mkdir $ZITI_HOME
export EXTERNAL_IP="$(curl -s eth0.me)"       
export ZITI_CTRL_EDGE_IP_OVERRIDE="${EXTERNAL_IP}"
export ZITI_ROUTER_IP_OVERRIDE="${EXTERNAL_IP}"
export ZITI_CTRL_ADVERTISED_ADDRESS="hapctrl.${base_dns}"
export ZITI_CTRL_EDGE_ADVERTISED_ADDRESS="hapctrl."${base_dns}
export ZITI_ROUTER_ADVERTISED_ADDRESS="haper.${base_dns}"
export ZITI_CTRL_ADVERTISED_PORT=${controller_port}
export ZITI_CTRL_EDGE_ADVERTISED_PORT=${controller_port}
export ZITI_ROUTER_PORT=${router_port}
export ZITI_ROUTER_LISTENER_BIND_PORT=${router_port}
read -sp "Enter ZITI_PWD: " ZITI_PWD && export ZITI_PWD
echo
expressInstall

echo ""
echo "express install complete."
echo "  - sed'ing controller config file for 0.0.0.0->127.0.0.1"
sed -i 's/0\.0\.0\.0/127.0.0.1/g' "${ZITI_HOME}/${ZITI_NETWORK}.yaml"

echo "  - sed'ing controller config file for ${controller_port}->${ha_proxy_port}"
sed -i "s/org:${controller_port}/org:${ha_proxy_port}/g" "${ZITI_HOME}/${ZITI_NETWORK}.yaml"

echo "  - sed'ing router config file for 0.0.0.0->127.0.0.1"
sed -i 's/0\.0\.0\.0/127.0.0.1/g' "${ZITI_HOME}/${ZITI_NETWORK}-edge-router.yaml"

echo "  - sed'ing router config file for ${controller_port}->${ha_proxy_port}"
sed -i "s/org:${controller_port}/org:${ha_proxy_port}/g" "${ZITI_HOME}/${ZITI_NETWORK}-edge-router.yaml"
echo "  - sed'ing router config file for ${router_port}->${ha_proxy_port}"
sed -i "s/org:${router_port}/org:${ha_proxy_port}/g" "${ZITI_HOME}/${ZITI_NETWORK}-edge-router.yaml"

