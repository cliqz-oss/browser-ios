//
//  CliqzSearchViewController.swift
//  BlurredTemptation
//
//  Created by Bogdan Sulima on 20/11/14.
//  Copyright (c) 2014 Cliqz. All rights reserved.
//

import UIKit
import WebKit
import Shared
import Storage

class HistoryListener {
    var historyResults: Cursor<Site>?
    static let shared = HistoryListener()
}

extension HistoryListener: LoaderListener {
    public func loader(dataLoaded data: Cursor<Site>) {
        self.historyResults = data
    }
}

protocol SearchViewDelegate: class {

    func didSelectURL(_ url: URL, searchQuery: String?)
    func searchForQuery(_ query: String)
    func autoCompeleteQuery(_ autoCompleteText: String)
	func dismissKeyboard()
}

let OpenUrlSearchNotification = NSNotification.Name(rawValue: "mobile-search:openUrl")
let CopyValueSearchNotification = NSNotification.Name(rawValue: "mobile-search:copyValue")
let HideKeyboardSearchNotification = NSNotification.Name(rawValue: "mobile-search:hideKeyboard")
let CallSearchNotification = NSNotification.Name(rawValue: "mobile-search:call")
let MapSearchNotification = NSNotification.Name(rawValue: "mobile-search:map")
let ShareLocationSearchNotification = NSNotification.Name(rawValue: "mobile-search:share-location")

class CliqzSearchViewController : UIViewController, KeyboardHelperDelegate, UIAlertViewDelegate  {
    
    fileprivate var lastQuery: String?
    
    let searchView = Engine.sharedInstance.rootView

    private static let KVOLoading = "loading"
    
    var privateMode = false
    var inSelectionMode = false
	
	fileprivate var searchBgImage: UIImageView?

    // for homepanel state because we show the cliqz search as the home panel
    var homePanelState: HomePanelState {
        return HomePanelState(isPrivate: privateMode, selectedIndex: 0)
    }

	weak var delegate: SearchViewDelegate?
	
	var searchQuery: String? {
		didSet {
			self.loadData(searchQuery!)
		}
	}
    
    var profile: Profile
    
    init(profile: Profile) {
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CliqzSearchViewController.showBlockedTopSites(_:)), name: NSNotification.Name(rawValue: NotificationShowBlockedTopSites), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didSelectUrl), name: OpenUrlSearchNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(copyValue), name: CopyValueSearchNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hideKeyboard), name: HideKeyboardSearchNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(call), name: CallSearchNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openMap), name: MapSearchNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shareLocation), name: ShareLocationSearchNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(searchEngineChanged), name: SearchEngineChangedNotification, object: nil)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

	override func viewDidLoad() {
		super.viewDidLoad()

        self.view.addSubview(searchView)
        self.searchView.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalToSuperview()
        }
		let bgView = UIImageView(image: UIImage.freshtabBackgroundImage())
		bgView.isHidden = true
		self.searchView.addSubview(bgView)
		bgView.snp.makeConstraints { (make) in
			make.left.right.top.bottom.equalToSuperview()
		}
		self.searchView.sendSubview(toBack: bgView)
		self.searchBgImage = bgView

		KeyboardHelper.defaultHelper.addDelegate(self)
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        
        NotificationCenter.default.addObserver(self, selector: #selector(showOpenSettingsAlert(_:)), name: NSNotification.Name(rawValue: LocationManager.NotificationShowOpenLocationSettingsAlert), object: nil)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

		self.updateBackgroundImage()
		self.searchBgImage?.isHidden = false

        self.updateExtensionPreferences()
        self.updateExtensionSearchEngine()
        
        NotificationCenter.default.addObserver(self, selector: #selector(searchWithLastQuery), name: NSNotification.Name(rawValue: LocationManager.NotificationUserLocationAvailable), object: nil)
	}
    
    override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: LocationManager.NotificationUserLocationAvailable), object: nil)
    }

	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
			self?.updateBackgroundImage()
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
    }

	func updateBackgroundImage() {
		if self.privateMode {
			self.searchBgImage?.image = UIImage(named: "forgetModeFreshtabBgImage")
		} else {
			self.searchBgImage?.image = UIImage.freshtabBackgroundImage()
		}
	}

    func sendUrlBarFocusEvent() {
        Engine.sharedInstance.getBridge().publishEvent("mobile-browser:urlbar-focus", args: [])
    }

	func isHistoryUptodate() -> Bool {
		return true
	}
    func searchWithLastQuery() {
        if let query = lastQuery {
            search(query)
        }
    }
    
	func loadData(_ query: String) {
        guard query != lastQuery else {
            return
        }
        if query == "" && lastQuery == nil {
            return
        }
        
		search(query)
	}
    
    fileprivate func search(_ query: String) {
        var parameters: Array<Any> = [query/*.escape()*/]
        if let l = LocationManager.sharedInstance.getUserLocation() {
            parameters += [true, l.coordinate.latitude, l.coordinate.longitude]
        }
        //self.javaScriptBridge.publishEvent("search", parameters: parameters)
        //TODO: Bridge can return null, so implement a queue, on Engine level.
        Engine.sharedInstance.getBridge().publishEvent("search", args: parameters)
        
        lastQuery = query
    }
    
    func updatePrivateMode(_ privateMode: Bool) {
        if privateMode != self.privateMode {
            self.privateMode = privateMode
			self.updateExtensionPreferences()
        }
		self.updateBackgroundImage()
    }

	fileprivate func animateSearchEnginesWithKeyboard(_ keyboardState: KeyboardState) {
        self.view.layoutIfNeeded()
	}

	// Mark Keyboard delegate methods
	func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
		animateSearchEnginesWithKeyboard(state)
	}

	func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) {
	}
	
	func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
		animateSearchEnginesWithKeyboard(state)
	}
	
	fileprivate func updateExtensionPreferences() {
		let isBlocked = SettingsPrefs.shared.getBlockExplicitContentPref()
        let subscriptions = SubscriptionsHandler.sharedInstance.getSubscriptions()
		let params = ["adultContentFilter" : isBlocked ? "conservative" : "liberal",
		              "incognito" : self.privateMode,
                      "backend_country" : self.getCountry(),
                      "suggestionsEnabled"  : QuerySuggestions.isEnabled(),
                      "subscriptions" : subscriptions] as [String : Any]
        
        //javaScriptBridge.publishEvent("notify-preferences", parameters: params)
        Engine.sharedInstance.getBridge().publishEvent("mobile-browser:notify-preferences", args: [params])
	}
    
    fileprivate func updateExtensionSearchEngine() {
            
        if let profile = (UIApplication.shared.delegate as? AppDelegate)?.profile {
            let searchComps = profile.searchEngines.defaultEngine.searchURLForQuery("queryString")?.absoluteString.components(separatedBy: "=queryString")
            let searchEngineName = profile.searchEngines.defaultEngine.shortName
            let parameters = ["name": searchEngineName, "url": searchComps![0] + "="]//"'\(searchEngineName)', `\(searchComps![0])=`"
            
            Engine.sharedInstance.getBridge().publishEvent("mobile-browser:set-search-engine", args: [parameters])
        }
    }
    
    fileprivate func getCountry() -> String {
        if let country = SettingsPrefs.shared.getRegionPref() {
            return country
        }
        return SettingsPrefs.shared.getDefaultRegion()
    }
	
    //MARK: - Reset TopSites
    func showBlockedTopSites(_ notification: Notification) {
        Engine.sharedInstance.getBridge().publishEvent("mobile-browser:restore-blocked-topsites", args: [])
    }
    
    //MARK: - Search Engine
    func searchEngineChanged(_ notification: Notification) {
        self.updateExtensionSearchEngine()
    }
}


//handle Search Events
extension CliqzSearchViewController {
    
    @objc func didSelectUrl(_ notification: Notification) {
        if let url_str = notification.object as? NSString, let encodedString = url_str.addingPercentEncoding(
            withAllowedCharacters: NSCharacterSet.urlFragmentAllowed), let url = URL(string: encodedString as String) {
            if !inSelectionMode {
                delegate?.didSelectURL(url, searchQuery: self.searchQuery)
            } else {
                inSelectionMode = false
            }
        }
    }
    
    @objc func hideKeyboard(_ notification: Notification) {
        delegate?.dismissKeyboard()
    }
    
    @objc func copyValue(_ notification: Notification) {
        if let result = notification.object as? String {
            UIPasteboard.general.string = result
        }
    }
    
    @objc func call(_ notification: Notification) {
        if let number = notification.object as? String {
            self.callPhoneNumber(number)
        }
    }
    
    @objc func openMap(_ notification: Notification) {
        if let url = notification.object as? String {
            self.openGoogleMaps(url)
        }
    }
    
    @objc func shareLocation(_ notification: Notification) {
        LocationManager.sharedInstance.shareLocation()
    }
    
    fileprivate func callPhoneNumber(_ phoneNumber: String) {
        let trimmedPhoneNumber = phoneNumber.removeWhitespaces()
        if let url = URL(string: "tel://\(trimmedPhoneNumber)") {
            UIApplication.shared.openURL(url)
        }
    }
    
    fileprivate func openGoogleMaps(_ url: String) {
        if let mapURL = URL(string:url) {
            delegate?.didSelectURL(mapURL, searchQuery: nil)
        }
    }
}

//MARK: - Util
extension CliqzSearchViewController {
    func showOpenSettingsAlert(_ notification: Notification) {
        var message: String!
        var settingsAction: UIAlertAction!
        
        let settingsOptionTitle = NSLocalizedString("Settings", tableName: "Cliqz", comment: "Settings option for turning on location service")
        
        if let locationServicesEnabled = notification.object as? Bool, locationServicesEnabled == true {
            message = NSLocalizedString("To share your location, go to the settings for the CLIQZ app:\n1.Tap Location\n2.Enable 'While Using'", tableName: "Cliqz", comment: "Alert message for turning on location service when clicking share location on local card")
            settingsAction = UIAlertAction(title: settingsOptionTitle, style: .default) { (_) -> Void in
                if let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) {
                    UIApplication.shared.openURL(settingsUrl)
                }
            }
        } else {
            message = NSLocalizedString("To share your location, go to the settings of your smartphone:\n1.Turn on Location Services\n2.Select the CLIQZ App\n3.Enable 'While Using'", tableName: "Cliqz", comment: "Alert message for turning on location service when clicking share location on local card")
            settingsAction = UIAlertAction(title: settingsOptionTitle, style: .default) { (_) -> Void in
                if let settingsUrl = URL(string: "App-Prefs:root=Privacy&path=LOCATION") {
                    UIApplication.shared.openURL(settingsUrl)
                }
            }
        }
        
        let title = NSLocalizedString("Turn on Location Services", tableName: "Cliqz", comment: "Alert title for turning on location service when clicking share location on local card")
        
        let alertController = UIAlertController (title: title, message: message, preferredStyle: .alert)
        
        let notNowOptionTitle = NSLocalizedString("Not Now", tableName: "Cliqz", comment: "Not now option for turning on location service")
        let cancelAction = UIAlertAction(title: notNowOptionTitle, style: .default, handler: nil)
        
        alertController.addAction(cancelAction)
        alertController.addAction(settingsAction)
        
        present(alertController, animated: true, completion: nil)
        
    }
}

