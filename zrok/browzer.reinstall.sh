SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

$SCRIPT_DIR/browzer.cleanup.sh

$SCRIPT_DIR/zrok.reinstall.sh

$SCRIPT_DIR/browzer.install.sh

source $SCRIPT_DIR/docker-whale
createService
