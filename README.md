Cliqz for iOS 
===============

Download on the [App Store](https://itunes.apple.com/de/app/cliqz-browser/id1065837334?mt=8).

The CLIQZ Browser for iOS is originally a fork of [Firefox's iOS Browser](https://github.com/mozilla/firefox-ios).

This branch
-----------

This branch is a stable branch prepared for the last version AppStore release, it also contains hot fixes required for the release.


This branch works with Xcode 7.3.1, and supports iOS 8.2 and 9.x. Although you can only run and debug from Xcode on a 9.2.1 device.

Please make sure you aim your pull requests in the right direction.

Building the code
-----------------

> __As of March 28, 2016, this project requires Xcode 7.3.__

1. Install the latest [Xcode developer tools](https://developer.apple.com/xcode/downloads/) from Apple.
1. Install Carthage

  ```shell
  brew update
  brew install carthage
  ```

1. Clone the repository:

  ```shell
  https://github.com/cliqz-oss/browser-ios/
  ```

1. Pull in the project dependencies:

  ```shell
  cd browser-ios
  sh ./checkout.sh
  ```

1. Open `Client.xcodeproj` in Xcode.
1. Build the `Fennec` scheme in Xcode.

It is possible to use [App Code](https://www.jetbrains.com/objc/download/) instead of Xcode, but you will still require the Xcode developer tools.
