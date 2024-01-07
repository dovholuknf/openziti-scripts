SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

$SCRIPT_DIR/browzer.cleanup.sh

$SCRIPT_DIR/zrok.reinstall.sh

$SCRIPT_DIR/browzer.install.sh

docker compose -f $SCRIPT_DIR/browzer-compose.yml pull
docker compose -f $SCRIPT_DIR/browzer-compose.yml down -v
docker compose -f $SCRIPT_DIR/browzer-compose.yml up -d
docker compose -f $SCRIPT_DIR/browzer-compose.yml logs
