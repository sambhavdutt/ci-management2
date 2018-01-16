#!/bin/bash -x

# Clone fabric git repository
#############################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric"
REPO_NAME=fabric
git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$REPO_NAME $WD
cd $WD || exit
#sed -i -e 's/127.0.0.1:7050\b/'"orderer:7050"'/g' $WD/common/configtx/tool/configtx.yaml
FABRIC_COMMIT=$(git log -1 --pretty=format:"%h")
echo "=======> FABRIC_COMMIT <======= $FABRIC_COMMIT"
make peer-docker && make orderer-docker
docker images | grep hyperledger

# Clone fabric-ca git repository
################################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca"
CA_REPO_NAME=fabric-ca
git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$CA_REPO_NAME $WD
cd $WD || exit
CA_COMMIT=$(git log -1 --pretty=format:"%h")
echo "======> CA_COMMIT <======= $CA_COMMIT"
make docker-fabric-ca
docker images | grep hyperledger

## Test fabric-sdk-node tests
################################

cd ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-node/test/fixtures || exit
docker-compose up >> dockerlogfile.log 2>&1 &
sleep 30
docker ps -a

cd ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-node || exit

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

npm install
npm config set prefix ~/npm && npm install -g gulp && npm install -g istanbul
gulp || exit 1
gulp ca || exit 1
rm -rf node_modules/fabric-ca-client && npm install

# Execute unit test and code coverage
echo "############"
echo "Run unit tests and Code coverage report"
echo "############"

gulp test

# copy debug log file to $WORKSPACE directory
if [ $? == 0 ]; then

# Copy Debug log to $WORKSPACE
cp /tmp/hfc/test-log/*.log $WORKSPACE
else
# Copy Debug log to $WORKSPACE
cp /tmp/hfc/test-log/*.log $WORKSPACE
exit 1

fi
