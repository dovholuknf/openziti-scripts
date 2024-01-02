SCRIPT_DIR="$(pwd)"

$SCRIPT_DIR/zrok.cleanup.sh
$SCRIPT_DIR/ziti.cleanup.sh
. $SCRIPT_DIR/ziti.install.sh
. $SCRIPT_DIR/zrok.install.sh
