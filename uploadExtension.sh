#!/usr/bin/env sh
#cd /Users/NS/Projects/quickfixExtension/navigation-extension/build/mobile/search/
cd $1
zip -r ../extension_latest.zip *
aws s3 cp ../extension_latest.zip s3://cdn.cliqz.com/mobile/extension_stable/extension_latest.zip --acl public-read
