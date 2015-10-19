Lookback.io
===========

Lookback is a tool and library for user experience testing that you can install into your app. Lookback records the iOS screen, the front-facing camera, microphone, metadata, touches and active views, and uploads it all in near-realtime to lookback.io where you can study and dive into the data.

Some use cases are:

* User testing sessions. Instead of mounting web cams in your testing lab to record both the screen and your tester's reactions, let Lookback do the hard work for you.
* Long-term usability study. Let a user record a week of using your app, and study trends, reactions and recurring problems.
* Quality assurance. Record videos of found bugs, complete with a trace of how the tester reached it.

For more examples, see [the Lookback example videos site](http://lookback.io/examples).

## Installation

### Getting Lookback into your app

The easiest way to add the Lookback SDK into your app is to use the [CocoaPods package manager](http://cocoapods.org). After setting up CocoaPods for your project, just add the following line to your Podfile:

    pod 'Lookback'

and run `pod install`.

If you would rather download the .framework and link to it manually, see the [manual installation guide online](http://lookback.io/docs/install-using-cocoapods).

### Setting up Lookback

Once Lookback has been linked into your app, you need to tell it who you are, and how to start recording. Thus, you must create an account and create a team and app with it. Once you have done so, you will get an "app token". You can then edit your app delegate to look something like below:

	// SRAppDelegate.m
	#import <Lookback/Lookback.h>
	@implementation SRAppDelegate	
	- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
	{
		.......
		[LookBack setupWithAppToken:@"<< YOUR APP TOKEN>>"];
		[LookBack lookback].shakeToRecord = YES;
		.......
	}

If you prefer to display the Lookback settings on your own instead of overriding the shake gesture, you can instead present GFSettingsViewController however you want, as long as it's wrapped in a navigation controller:

	- (IBAction)showLookbackSettings:(id)sender
	{
		UIViewController *settings = [GFSettingsViewController settingsViewControllerForInstance:[LookBack lookback]];
		UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:settings];
		settings.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissSettings)];
		[self.window.rootViewController presentViewController:nav animated:YES completion:nil];
	}

You're now ready to record! To use additional features of the SDK, please see the [Lookback documentation site](http://lookback.io/docs/customizing) and the LookBack.h header file.

## FAQ

### Why are my view controller names not logged correctly?

Lookback figures out which view controllers are on screen and maps them to timestamps in the video recording. Lookback will use your view controller's class name and make it human readable. If you implement `+(NSString*)lookBackIdentifier`, that will be used instead.

NOTE: This information is picked up in `-[UIViewController viewDidAppear:]` and `-[UIViewController viewWillDisappear:]`. If you override these methods in your view controllers and don't call super, the view names will not be logged! Your viewDidAppear: should always look like this:

	- (void)viewDidAppear:(BOOL)animated {
		[super viewDidAppear:animated];
		...
	}

### What does the "Upload when inactive" option mean?

Normally when you start a recording, it will be paused whenever the application becomes inactive (backgrounded or screen locked). If you record a very long session, it will take a long time to upload, and be difficult to manage. In this case, you might want to enable the "Upload when inactive" option. Then, recording will stop when the app is inactive, the short session uploaded, and a new recording started anew when the app becomes active.
