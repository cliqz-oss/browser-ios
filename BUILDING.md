> These are the instructions for building the *master* branch which contains a stable version just before releasing. If you need up to date version user development branch.

Building Cliqz for iOS
========================

Prerequisites, as of *July 21, 2016*:

* Mac OS X 10.11.4
* Xcode 7.3 GM with the iOS 9.3 GM SDK (Newer betas not supported)
* Carthage 0.15 or newer


When running on a device:

* A device that supports iOS 8.2 GM
* One of the following:
 * A developer account and Admin access to the *Certificates, Identifiers & Profiles* section of the *iOS DevCenter*
 * A free developer account, new with Xcode 7

Get the Code
-----------

```
git clone https://github.com/cliqz-oss/browser-ios
cd browser-ios
```

(If you have forked the repository, substitute the URL with your own repository location.)

Pull in Dependencies
--------------------

We use Carthage to manage projects that we depend on. __The build will currently only work with Carthage v0.15 or newer__. If you do not already have Carthage installed, you need to grab it via Homebrew. Assuming you have Homebrew installed, execute the following:

```
brew update
brew upgrade
brew install carthage
```


You can now execute our `checkout.sh` script:

```
./checkout.sh
```


At this point you have checked out the source code for both the Cliqz for iOS project and it's dependencies. You can now build and run the application.

Everything after this point is done from within Xcode.

Run on the Simulator
-----------------

* Open `Client.xcodeproj` and make sure you have the *Fennec* scheme and a simulated device selected. The app should run on any simulator. We just have not tested very well on the *Resizable iPad* and *Resizable iPhone* simulators.
* Select *Product -> Run* and the application should build and run on the selected simulator.

Run on a Device with Xcode 7 and a Free Developer Account
---------------

> Only follow these instructions if you are using the new free personal developer accounts that Apple enabled with Xcode 7.

Since the bundle identifier we use for Cliqz is tied to our developer account, you'll need to generate your own identifier and update the existing configuration.

1. Open Client/Configuration/Fennec.xcconfig
2. Change MOZ_BUNDLE_ID to your own bundle identifier.
3. Navigate to each of the application targets (Client/SendTo/ShareTo/ViewLater) and for each one:
  1. select your personal development account
  2. remove the code signing entitlements
  3. change Bundle Identifier to your own identifier.

If you submit a patch, be sure to exclude these files because they are only relevant for your personal build.

Now when you run the app for the first time on your device, Xcode will tell you that it does not have a provisioning profile for the four application components and it will specifically mention a bundle identifier that contains your unique reverse domain.

For each component it complains about, select *Fix This* to let Xcode resolve this. You may have to go through this process a couple of times. It is buggy. But then the app should properly build and run.

> If after building, Xcode fails to run the app with a vague `Security` error, open Settings -> Profiles on your iOS Device and Trust your personal developer profile. This may only happen on iOS 9.

Run on a Device
---------------

These are instructions for development. Not production / distribution.

> Before you try to run the application on a device, it is highly recommended that you first make sure that you can run applications on device in general. Just create one of the built-in iOS templates that Xcode provides and make sure you can run that on your device. If you can then it means you have done the basic setup like pairing your device, registering its UDID in the dev center, etc.

Before you can run the application on your device, you need to setup a few things in the *Certificates, Identifiers & Profiles* section of the iOS Developer Center.

> _Note_: When we mention `YOURREVEREDOMAIN` below, use your own domain in reverse notation like `com.example` or if you do not have your own domain, just use something unique and personal like `io.github.yourgithubusername`. Please do not use existing domain names which you do not own.

1. Create a Application Group. Name this group whatever you want e.g. 'XXX' and for its Identifier use `group.YOURREVERSEDOMAIN.XXX`
2. Create a new App Id. Name it 'XXX'. Give it an Explicit App ID and set its Bundle Identifier to `YOURREVERSEDOMAIN.XXX`. In the App Services section, select *App Groups*.
3. Create a new App Id. Name it 'XXX ShareTo'. Give it an Explicit App ID and set its Bundle Identifier to `YOURREVERSEDOMAIN.XXX.ShareTo`. In the App Services section, select *App Groups*.
4. Create a new App Id. Name it 'XXX SendTo'. Give it an Explicit App ID and set its Bundle Identifier to `YOURREVERSEDOMAIN.XXX.SendTo`. In the App Services section, select *App Groups*.
5. Create a new App Id. Name it 'XXX ViewLater'. Give it an Explicit App ID and set its Bundle Identifier to `YOURREVERSEDOMAIN.XXX.ViewLater`. In the App Services section, select *App Groups*.
6. Create a new App Id. Name it 'XXX Today'. Give it an Explicit App ID and set its Bundle Identifier to `YOURREVERSEDOMAIN.XXX.Today`. In the App Services section, select *App Groups*.
7. For all App Ids that you just created, edit their App Groups and make sure they are all part of the Fennec App Group that you created in step 1.

Now we are going to create three Provisioning Profiles that are linked to the App Ids that we just created:

1. Create a new *Development Provisioning Profile* and link it to the *XXX* App ID that you created. Select the *Developer Certificates* and *Devices* that you wish to include in this profile. Finally, name this profile *XXX*.
2. Create a new *Development Provisioning Profile* and link it to the *XXX SendTo* App ID that you created. Select the *Developer Certificates* and *Devices* that you wish to include in this profile. Finally, name this profile *XXX SendTo*.
3. Create a new *Development Provisioning Profile* and link it to the *XXX ShareTo* App ID that you created. Select the *Developer Certificates* and *Devices* that you wish to include in this profile. Finally, name this profile *XXX ShareTo*.
4. Create a new *Development Provisioning Profile* and link it to the *XXX ViewLater* App ID that you created. Select the *Developer Certificates* and *Devices* that you wish to include in this profile. Finally, name this profile *XXX ViewLater*.
5. Create a new *Development Provisioning Profile* and link it to the *XXX Today* App ID that you created. Select the *Developer Certificates* and *Devices* that you wish to include in this profile. Finally, name this profile *XXX Today*.

Now go to Xcode, *Preferences -> Accounts* and select your developer account. Hit the *View Details* button and then press the little reload button in the bottom left corner. This should sync the Provisioning Profiles and you should see the three profiles appear that you creates earlier.

Almost done. The one thing missing is that we need to adjust the following files in the project:

* `Client/Configuration/BaseConfig.xcconfig`
* `Client/Info.plist`
* `Client/Fennec.entitlements`
* `Extensions/ShareTo/Info.plist`
* `Extensions/ShareTo/Fennec.entitlements`
* `Extensions/SendTo/Info.plist`
* `Extensions/SendTo/Fennec.entitlements`
* `Extensions/ViewLater/Info.plist`
* `Extensions/ViewLater/Fennec.entitlements`

In all these files, replace occurrences of `org.mozilla.ios` with `YOURREVERSEDOMAIN`. Make sure you expand all the fields of the `.entitlements` files. Make sure you just replace the `org.mozilla.ios` part and keep prefixes like `group.` that some files contain.

Before building, do *Product -> Clean Build Folder* (option-shift-command-k)

You should now be able to build the *Client* scheme and run on your device.

We would love a Pull Request for a smarter Xcode project configuration or even a shell script that makes this process simpler.


Random notes
------------

Updating SQLCipher.

As of bug https://bugzilla.mozilla.org/show_bug.cgi?id=1182620 we do not run the SQLCipher 'amalgamation' phase anymore. Instead we have simply included generated copies of `sqlite3.c`, `sqlite3.h` and `sqlite3ext.h` in the project. This works around problems where the amalgamation phase did not work for production builds. It also speeds up things.

To update to a newer version of SQLCipher: check out the original SQLCipher project and build it. Do not copy the project or anything in the Firefox project. Just follow their instructions. Then copy the above three `.c` and `.h` files back into the Firefox project. Also update the `README`, `VERION` and `CHANGELOG` files from the original distribution so that we know what version we have included.
