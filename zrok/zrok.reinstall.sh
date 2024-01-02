SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

$SCRIPT_DIR/zrok.cleanup.sh
$SCRIPT_DIR/ziti.cleanup.sh
. $SCRIPT_DIR/ziti.install.sh
. $SCRIPT_DIR/zrok.install.sh
