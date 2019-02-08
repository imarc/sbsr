#!/bin/bash

ROOT=$(dirname "$(readlink -f "$0")")
USER=$(stat -c "%U" $ROOT)
EXEC="/home/$USER/.composer/vendor/bin/dep"
CONF="$ROOT/deploy.php"

if [[ `whoami` != $USER ]]; then
        sudo -u $USER $EXEC --file=$CONF  "$@"
else
        $EXEC --file=$CONF  "$@"
fi
