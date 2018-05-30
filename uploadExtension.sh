#!/usr/bin/env sh
#cd /Users/NS/Projects/quickfixExtension/navigation-extension/build/mobile/search/
cd $1
zip -r ../extension.zip *
aws s3 cp ../extension.zip s3://cdn.cliqz.com/mobile/extension_stable/extension.zip --acl public-read
