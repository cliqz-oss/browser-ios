#!/usr/bin/env sh
JSENGINE_RELEASE=latest

# when jsengine is in navigation-extenion, we can pull tags from there. In the meantime we'll
# put them on cdn.cliqz.com
BASE_RELEASE_URL=https://s3.amazonaws.com/cdn.cliqz.com/mobile/jsengine
BUNDLE_NAME=jsengine.bundle.$JSENGINE_RELEASE
PACKAGEJSON_PATH=package.json.$JSENGINE_RELEASE

# enter JSEngine directory
mkdir -p ./JSEngine && cd ./JSEngine

curl -O $BASE_RELEASE_URL/$BUNDLE_NAME.gz
curl -O $BASE_RELEASE_URL/$PACKAGEJSON_PATH
gunzip ./$BUNDLE_NAME.gz -d && mv $BUNDLE_NAME jsengine.bundle.js
mv $PACKAGEJSON_PATH package.json

# install react dependencies
npm install

# exit JSEngine directory
cd ../
pod install
