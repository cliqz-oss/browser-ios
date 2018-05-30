#!/usr/bin/env sh
curl -O  https://s3.amazonaws.com/cdn.cliqz.com/mobile/extension_stable/extension_latest.zip
unzip ./extension_latest.zip -d ./Extension
rm ./extension_latest.zip
