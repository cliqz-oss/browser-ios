#!/usr/bin/env sh
curl -O  https://s3.amazonaws.com/cdn.cliqz.com/mobile/extension_stable/extension.zip
unzip ./extension.zip -d ./Extension
rm ./extension.zip
