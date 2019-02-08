#!/bin/bash

USER=$(stat -c "%U" $ROOT)
EXEC=__DIR__ . "/vendor/bin/dep"
CONF=__DIR__ . "/deploy.php"

if [[ `whoami` != $USER ]]; then
		sudo -u $USER $EXEC --file=$CONF  "$@"
else
		$EXEC --file=$CONF  "$@"
fi
