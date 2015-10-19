#import <Foundation/Foundation.h>
@class NSScreen;

typedef NS_ENUM(NSInteger, LookbackTimeoutOption) {
	LookbackTimeoutImmediately = 0,
	LookbackTimeoutAfter1Minutes = 60,
	LookbackTimeoutAfter3Minutes = 180,
	LookbackTimeoutAfter5Minutes = 300,
	LookbackTimeoutAfter15Minutes = 900,
	LookbackTimeoutAfter30Minutes = 1800,
	LookbackTimeoutNever = NSIntegerMax,
};

typedef NS_ENUM(NSInteger, LookbackAfterRecordingOption) {
	LookbackAfterRecordingReview = 0,
	LookbackAfterRecordingUpload,
	LookbackAfterTimeoutUploadAndStartNewRecording,
};

/*! All the customizations you can do to Lookback. Customize default options,
	or create a new instance and use special options only for a specific recording.
*/
@interface LookbackRecordingOptions : NSObject <NSCopying>
/*! Return a new LookbackRecordingOptions with all the defaults from the global options.
	Customize as you will, then start a recording with it.*/
- (instancetype)init;

/*! The NSTimeInterval/double key LookbackRecordingTimeoutOptionSettingsKey controls the timeout option when
	the app becomes inactive. "Inactive" in this context means that the user exists the app, or locks the screen.
	
	* Using 0 will stop a recording as soon as the app becomes inactive.
	* Using DBL_MAX will never terminate a recording when the app becomes inactive.
	* Any value in between will timeout and end the recording after the app has been inactive for
	  the specified duration.
 */
@property(nonatomic) LookbackTimeoutOption timeout;

/*! The LookbackAfterRecordingOption key LookbackAfterRecordingOptionSettingsKey controls the behavior of
	Lookback when the user stops recording, or recording times out (see LookbackRecordingTimeoutSettingsKey).
	* LookbackAfterRecordingReview will let the user manually review a recording after it's been stopped.
	* LookbackAfterRecordingUpload will automatically upload without review.
	* LookbackAfterTimeoutUploadAndStartNewRecording will automatically start uploading, but if it was stopped
	  because of a timeout, it will also start a new recording the next time the app is brought to the foreground.
 */
@property(nonatomic) LookbackAfterRecordingOption afterRecording;

/*! When doing a Lookback screen recording, should the user's face also be recorded through the device's front-facing camera? */
@property(nonatomic) BOOL cameraEnabled;

/*! When doing a Lookback screen recording, should the user's voice also be recorded through the device's microphone? */
@property(nonatomic) BOOL microphoneEnabled;

/*! Lookback automatically sets a screen recording framerate that is suitable for your
	device. However, if your app is very performance intense, you might want to decrease
	the framerate at which Lookback records to free up some CPU time for your app. This
	multiplier lets you adapt the framerate that Lookback chooses for you to something
	more suitable for your app.
	
	Default value: 1.0
	Range: 0.1 to 1.0
	
	@see framerateLimit
*/
@property(nonatomic) float framerateMultiplier;

/*! Set a specific upper limit on screen recording framerate. Note that Lookback adapts framerate to something suitable for the current device: setting the framerate
	manually will override this. Set it to 0 to let Lookback manage the framerate limit.
	
	Decreasing the framerate is the best way to fix performance problems with Lookback. However, instead of hard-coding
	a specific framerate, consider setting -[Lookback framerateMultiplier] instead, as this will let Lookback adapt the
	framerate to something suitable for your device.
	
	Default value: Depends on hardware
	Range: 1 to 60
	@see framerateMultiplier
*/
@property(nonatomic) int framerateLimit;

/*! Taking into account the performance of your iOS device and the framerateMultiplier, what framerate does Lookback recommend? */
- (int)recommendedFramerateLimit;

/*! Whether the user should be shown a preview image of their face at the bottom-right of the screen while recording, to make sure that they are holding their device correctly and are well-framed. */
@property(nonatomic) BOOL showCameraPreviewWhileRecording;

/*! Identifier for the user who's currently using the app. You can filter on
    this property at lookback.io later. If your service has log in user names,
    you can use that here. Optional.
    @seealso http://lookback.io/docs/log-username
*/
@property(nonatomic,copy) NSString *userIdentifier;

/*! Default YES. With this setting, all the view controllers you visit during a
	recording will be recorded, and their names displayed on the timeline. Disable
	this to not record view names, or to manually track view names using enteredView:
	and exitedView:.
	
	If you wish to customize the name that your view controller is logged as,
	you can implement +(NSString*)lookbackIdentifier in your view controller.
	*/
@property(nonatomic) BOOL automaticallyRecordViewControllerNames;

#if TARGET_OS_MAC && !TARGET_OS_IPHONE

/*! The camera that Lookback will use whilst recording. This is the system defined name for available cameras that are available. An empty string means no camera selected
	
	Default value: @""
*/
@property(nonatomic) NSString *cameraName;

/*! The microphone that Lookback will use whilst recording. This is the system defined name for available microphones that are available. An empty string means no microphone selected
	
	Default value: @""
*/
@property(nonatomic) NSString *microphoneName;

/*! The ID of the screen that Lookback will record. Retrieve the ID of a screen
	by using [screen.deviceDescription[@"NSScreenNumber"] intValue].
	
	Default value: 0, which means the main screen.
*/
@property(nonatomic) uint32_t screenId;

/*! The rectangle of the screen area that Lookback will record.
	
	Default value: CGRectZero, which means record the whole screen.
*/
@property(nonatomic) CGRect screenCrop;

/*! The pixel density of the screen that Lookback will use whilst recording. A one means standard pixel density.
	
	Default value: 1.0
*/
@property(nonatomic) float pixelDensity;

/*! Whether we show the mouse clicks on the captured video
	
	Default value: NO
*/
@property(nonatomic) BOOL captureClicks;

#endif

/*! @group Callbacks
*/

/*! When a recording upload starts, its URL is determined. You can then attach this URL to a bug report or similar.

    @example <pre>
        // Automatically put a recording's URL on the user's pasteboard when recording ends and upload starts.
		[Lookback sharedLookback].options.onStartedUpload = ^(NSURL *destinationURL, NSDate *sessionStartedAt) {
			if(fabs([sessionStartedAt timeIntervalSinceNow]) < 60*60) // Only if it's for an experience we just recorded
				NSLog(@"Session URL %@ now in clipboard", destinationURL);
				[UIPasteboard generalPasteboard].URL = destinationURL;
		};
		</pre>
*/
@property(nonatomic,copy) void(^onStartedUpload)(NSURL *destinationURL, NSDate *sessionStartedAt);

@end

/*! These are automatically saved to NSUserDefaults when modified. You may only use the instance [Lookback sharedLookback].options.*/
@interface LookbackDefaultRecordingOptions : LookbackRecordingOptions
@end
