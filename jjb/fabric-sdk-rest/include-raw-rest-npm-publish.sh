#!/bin/bash -eu

#################################################
#Publish npm module as unstable after merge commit
#npm publish --tag unstable
#Run this "npm dist-tags ls $pkgs then look for
#unstable versions
#################################################

set -o pipefail

npmPublish() {
  if [ $RELEASE = "snapshot" ]; then
    echo
    UNSTABLE_VER=$(npm dist-tags ls "$1" | awk '/unstable/{
    ver=$NF
    sub(/.*\./,"",rel)
    sub(/\.[[:digit:]]+$/,"",ver)
    print ver}')

    echo "===> UNSTABLE VERSION --> $UNSTABLE_VER"

    UNSTABLE_INCREMENT=$(npm dist-tags ls "$1" | awk '/unstable/{
    ver=$NF
    rel=$NF
    sub(/.*\./,"",rel)
    sub(/\.[[:digit:]]+$/,"",ver)
    print ver"."rel+1}')

    echo "===> Incremented UNSTABLE VERSION --> $UNSTABLE_INCREMENT"

    if [ "$UNSTABLE_VER" = "$CURRENT_RELEASE" ]; then
      # Replace existing version with Incremented $UNSTABLE_VERSION
      sed -i 's/\(.*\"version\"\: \"\)\(.*\)/\1'$UNSTABLE_INCREMENT\"\,'/' package.json
      npm publish --tag unstable
    else
      # Replace existing version with $CURRENT_RELEASE
      sed -i 's/\(.*\"version\"\: \"\)\(.*\)/\1'$CURRENT_RELEASE\"\,'/' package.json
      npm publish --tag unstable
    fi

  else
      if [[ "$RELEASE" =~ alpha*|beta*|rc*|^[0-9].[0-9].[0-9]$ ]]; then
        echo "===> PUBLISH --> $RELEASE"
        npm publish
      else
        echo "$RELEASE: No such release."
        exit 1
      fi
  fi
}

versions() {

  CURRENT_RELEASE=$(cat package.json | grep version | awk -F\" '{ print $4 }')
  echo "===> Current Version --> $CURRENT_RELEASE"

  RELEASE=$(cat package.json | grep version | awk -F\" '{ print $4 }' | cut -d "-" -f 2)
  echo "===> Current Release --> $RELEASE"
}

cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric-sdk-rest
npm config set //registry.npmjs.org/:_authToken=$NPM_TOKEN

cd packages/fabric-rest
versions
npmPublish fabric-rest

cd ../loopback-connector-fabric
versions
npmPublish loopback-connector-fabric
