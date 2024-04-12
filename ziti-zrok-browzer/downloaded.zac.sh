ZAC_VERSION=3.0.8
mkdir -p $ZITI_HOME/zac/downloads
wget -O $ZITI_HOME/zac/downloads/zac-${ZAC_VERSION}.zip https://github.com/openziti/ziti-console/releases/download/app-ziti-console-v${ZAC_VERSION}/ziti-console.zip
unzip $ZITI_HOME/zac/downloads/zac-${ZAC_VERSION}.zip -d $ZITI_HOME/zac/${ZAC_VERSION}
cat <<HERE

Now update your controller config. Your file is located at:

	$ZITI_HOME/${ZITI_NETWORK}.yaml

Find these lines:
#      - binding: zac
#        options: { "location": "./zac", "indexFile":"index.html" }

and update them to:
      - binding: zac
        options: { "location": "$ZITI_HOME/zac/${ZAC_VERSION}", "indexFile":"index.html" }

Once done, restart your controller.

Optionally - split the management and client apis and add zac to the 'management' api section
HERE
