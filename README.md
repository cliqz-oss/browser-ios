Cliqz for iOS 
===============

Download on the [App Store](https://itunes.apple.com/ro/app/cliqz-browser-search-engine/id1065837334?mt=8).

This branch
-----------

This branch is for mainline development.

Building the code
-----------------

1. Install the latest [Xcode developer tools](https://developer.apple.com/xcode/downloads/) from Apple.
1. Install Carthage

  ```shell
  brew update
  brew install carthage
  ```

1. Clone the repository:

  ```shell
  git clone https://github.com/mozilla/firefox-ios
  ```

1. Pull in the project dependencies:

  ```shell
  cd browser-ios
  sh ./bootstrap.sh
  ```

1. Get dependencies for react-native:

  ```shell
  npm install
  pod install
  ```

1. Build react-native bundle

  ```shell
  npm run dev-bundle
  ```

1. Open `Client.xcodeproj` in Xcode.
1. Build the `Fennec` scheme in Xcode.

It is possible to use [App Code](https://www.jetbrains.com/objc/download/) instead of Xcode, but you will still require the Xcode developer tools.

### React Native

This branch uses react-native for background javascript. The bootstrap setup will automatically setup the react-native environment, and create a XCode workspace which you should use to open the project.

#### React debug tools

You can enable extra debug tools for React by passing a `DEBUG` flag to the react module:

 1. In the `Pods.xcodeproj` go to build settings
 2. Under `Preprocessor Macros` add a `DEBUG=1` option for the `Fennec` build.
 3. Now React debug options will be available after a 'shake' gesture in the app.

#### Developing JS code

By default React uses the `jsengine.bundle.js` code bundle to run. In order to develop you can use the react-native command line tools to auto re-generate this bundle when you change the code.

 1. Start react-native dev server
  ```shell
  npm run dev-server
  ```

 2. Configure react to use the debug server: in `Client.xcodeproj` under build settings, go to 'Other Swift Flags' and add `-DReact_Debug` to the `Fennec` flags.

 3. Now the app will load code provided by the bundler when starting.

 4. Checkout a copy of [browser-core](https://github.com/cliqz-oss/browser-core) (Cliqzers, use [navigation-extension](https://github.com/cliqz/navigation-extension) for non-release versions).

 5. Get browser-core dependencies::
 ```shell
 cd /path/to/browser-core
 ./fern.js install
 ```

 6. Build browser-core with the `react-native.json` config, and output to node_modules for `browser-ios`:
 ```shell
 CLIQZ_OUTPUT_PATH=/path/to/browser-ios/node_modules/browser-core/build/ ./fern.js serve configs/react-native.json
 ```

With this workflow, any code changes will be automatically rebuild, then you can reload the js bundle in the app (running in the emulator) to see the changes.

#### Debugging JS code

The Cliqz extension modules are exposed to debuggers via the `app` global variable. You can use this as an entry point to inspect the state of the app.

#### Creating a new bundle

You can create a new js bundle using the react-native cli:

```shell
npm run dev-bundle
```


## Contributor guidelines

### Swift style
* Swift code should generally follow the conventions listed at https://github.com/raywenderlich/swift-style-guide.
  * Exception: we use 4-space indentation instead of 2.

### Whitespace
* New code should not contain any trailing whitespace.
* We recommend enabling both the "Automatically trim trailing whitespace" and "Including whitespace-only lines" preferences in Xcode (under Text Editing).
* <code>git rebase --whitespace=fix</code> can also be used to remove whitespace from your commits before issuing a pull request.

### Commits
* Each commit should have a single clear purpose. If a commit contains multiple unrelated changes, those changes should be split into separate commits.
* If a commit requires another commit to build properly, those commits should be squashed.
* Follow-up commits for any review comments should be squashed. Do not include "Fixed PR comments", merge commits, or other "temporary" commits in pull requests.
