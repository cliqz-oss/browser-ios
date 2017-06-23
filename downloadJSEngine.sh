#!/usr/bin/env sh
JSENGINE_RELEASE=ci
PLATFORM=ios

# when jsengine is in navigation-extenion, we can pull tags from there. In the meantime we'll
# put them on cdn.cliqz.com
BASE_RELEASE_URL=https://s3.amazonaws.com/cdn.cliqz.com/mobile/jsengine
BUNDLE_NAME=jsengine.$PLATFORM.$JSENGINE_RELEASE.tar.gz

# enter JSEngine directory
mkdir -p ./JSEngine && cd ./JSEngine

curl -O $BASE_RELEASE_URL/$BUNDLE_NAME
tar -xf $BUNDLE_NAME
rm $BUNDLE_NAME

# install react dependencies
npm install

# exit JSEngine directory
cd ../
pod install
