#!/bin/bash -e
set -o pipefail

# RUN END-to-END Test
#####################
rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-node

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-node"
SDK_REPO_NAME=fabric-sdk-node
git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$SDK_REPO_NAME $WD
cd $WD
SDK_NODE_COMMIT=$(git log -1 --pretty=format:"%h")
echo "SDK_NODE_COMMIT=======> $SDK_NODE_COMMIT" >> ${WORKSPACE}/gopath/src/github.com/hyperledger/commit.log
cd test/fixtures
docker rm -f "$(docker ps -aq)" || true
docker-compose up >> node_dockerlogfile.log 2>&1 &
sleep 10
docker ps -a
cd ../..

# Install nvm to install multi node versions
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash
# shellcheck source=/dev/null
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
# Install nodejs version 6.9.5
nvm install 6.9.5 || true

# use nodejs 6.9.5 version
nvm use --delete-prefix v6.9.5 --silent

echo "npm version ======>"
npm -v
echo "node version =======>"
node -v

npm install && npm config set prefix ~/npm && npm install -g gulp && npm install -g istanbul
gulp || exit 1
gulp ca || exit 1
rm -rf node_modules/fabric-ca-client && npm install

# Execute unit test and code coverage
echo "############"
echo "Run e2e tests and Code coverage report"
echo "############"

istanbul cover --report cobertura test/integration/e2e.js

function clearContainers () {
    CONTAINER_IDS=$(docker ps -aq)
        if [ -z "$CONTAINER_IDS" ] || [ "$CONTAINER_IDS" = " " ]; then
                echo "---- No containers available for deletion ----"
        else
                docker rm -f $CONTAINER_IDS || true
                docker ps -a
        fi
}

function removeUnwantedImages() {
        DOCKER_IMAGE_IDS=$(docker images | grep "dev\|none\|test-vp\|peer[0-9]-" | awk '{print $3}')
        if [ -z "$DOCKER_IMAGE_IDS" ] || [ "$DOCKER_IMAGE_IDS" = " " ]; then
                echo "---- No images available for deletion ----"
        else
                docker rmi -f $DOCKER_IMAGE_IDS || true
                docker images
        fi
}

clearContainers
removeUnwantedImages
