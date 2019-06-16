#!/bin/bash

#declare -r SPIRE_URL="http://s3.us-east-2.amazonaws.com/scytale-artifacts/spire/spire-b90d108-linux-x86_64-glibc.tar.gz"
#declare -r SPIRE_URL="https://github.com/spiffe/spire/releases/download/0.6.1/spire-0.6.1-linux-x86_64-glibc.tar.gz"
declare -r SPIRE_URL="https://github.com/spiffe/spire/releases/download/0.8.0/spire-0.8.0-linux-x86_64-glibc.tar.gz"
declare -r SPIRE_DIR="/opt/spire"

curl --progress-bar --location ${SPIRE_URL} | tar xzf -
mv `ls -d spire-0.?.? | head -1` spire
echo "directory listing : ------"
ls -la
echo "end directory listing : ------"
rm -rf ${SPIRE_DIR}
mv -v spire /opt/spire/
chmod -R 777 ${SPIRE_DIR}
mkdir -p ${SPIRE_DIR}/.data

# Clean installation files
rm install_spire.sh
