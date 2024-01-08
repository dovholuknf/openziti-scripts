exitWithError() {
    echo -e "Error: $1"
    exit 1
}

if [ "$#" -eq 0 ]; then
    exitWithError "One parameter is required. \n       The parameter should be the location of a file \n       with the necessary environment variables set.\n"
fi

export ENV_VAR_FILE="$1"
if [ ! -f "$ENV_VAR_FILE" ]; then
    exitWithError "File '$ENV_VAR_FILE' does not exist.\nPlease provide a valid file."
fi
source $ENV_VAR_FILE

export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

$SCRIPT_DIR/install.ziti.sh
$SCRIPT_DIR/install.zrok.sh
$SCRIPT_DIR/install.browzer.sh