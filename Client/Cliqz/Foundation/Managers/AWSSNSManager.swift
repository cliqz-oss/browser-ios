//
//  AWSSNSManager.swift
//  Client
//
//  Created by Sahakyan on 4/19/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation

class AWSSNSManager {
	
	static let tokenKey = "Token"
	
	static let cognitoIdentityPoolID = "us-east-1:81faca92-4d48-437c-ad68-e28ca03411fe"
//	static let SNSAplicationArn = "arn:aws:sns:us-east-1:141047255820:app/APNS_SANDBOX/Cliqz_Beta_for_iOS"
	static let SNSAplicationArn = "arn:aws:sns:us-east-1:141047255820:app/APNS/CLIQZ_Browser_for_iOS"
	static let cognitoRegionID = AWSRegionType.USEast1
	
	class func configureCongnitoPool() {
		let credentialsProvider = AWSCognitoCredentialsProvider(
			regionType: cognitoRegionID,
			identityPoolId: cognitoIdentityPoolID)
		let defaultServiceConfiguration = AWSServiceConfiguration(
			region: cognitoRegionID,
			credentialsProvider: credentialsProvider)
		AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = defaultServiceConfiguration
	}
	
	class func createPlatformEndpoint(deviceToken: String) {
		if let oldToken = (LocalDataStore.objectForKey(tokenKey) as? String) where oldToken == deviceToken {
			return
		}

		let sns = AWSSNS.defaultSNS()
		let request = AWSSNSCreatePlatformEndpointInput()
		request.token = deviceToken
		request.platformApplicationArn = SNSAplicationArn
		sns.createPlatformEndpoint(request).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task: AWSTask!) -> AnyObject! in
			if task.error != nil {
				print("Error Creating Endpoint: \(task.error)")
				LocalDataStore.removeObjectForKey(tokenKey)
			} else {
				let createEndpointResponse = task.result as! AWSSNSCreateEndpointResponse
				if let endpointArn = createEndpointResponse.endpointArn {
					subscriptForTopic(endpointArn)
					LocalDataStore.setObject(deviceToken, forKey: tokenKey)
				}
			}
			return nil
		})
	}
	
	class func subscriptForTopic(endpointArn: String) {
		let sns = AWSSNS.defaultSNS()
		let input = AWSSNSSubscribeInput()
		input.topicArn = "arn:aws:sns:us-east-1:141047255820:mobile_news"
		input.endpoint = endpointArn
		input.protocols = "application"
		sns.subscribe(input, completionHandler: { (response, error) -> Void in
			if error != nil {
				print("Error subscribing for a topic: \(error)")
			} else {
				print("Subscribtion succeeded")
			}
		})
	}
}