#!/bin/bash

ROOT=$(dirname "$(readlink -f "$0")")
USER=$(stat -c "%U" $ROOT)

DCMD="$ROOT/vendor/bin/dep"
EXEC="$ROOT/deploy.php"
CONF="$ROOT/deploy.yml"

if [[ `whoami` != $USER ]]; then
	sudo -u $USER $0 "$@"
else
	$DCMD --file=$EXEC "$@"
fi
