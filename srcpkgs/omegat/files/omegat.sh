#!/bin/sh
cd /opt/omegat/ || exit 1
java -jar -Xmx1024M OmegaT.jar "$@"
