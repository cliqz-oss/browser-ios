//
//  Crypto.swift
//  Client
//
//  Created by Mahmoud Adam on 7/17/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit
import React


@objc(Crypto)
open class Crypto : RCTEventEmitter {
    private let privateKeyTag = "com.connect.cliqz.private"
    private let publicKeyTag = "com.connect.cliqz.public"
    
    
    @objc(generateRandomSeed:reject:)
    func generateRandomSeed(_ resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) -> Void {
        let length = 128
        if let randomSeed = generateRandomBytes(length) {
            resolve(randomSeed)
        } else {
            reject("RandomNumberGenerationFailure", "Could not generate random seed", nil)
        }
    }
    
    @objc(generateRSAKey:reject:)
    func generateRSAKey(_ resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) -> Void {
        
        let privateKeyAttr : [String: Any] = [
            kSecAttrIsPermanent as String: kCFBooleanTrue,
            kSecAttrApplicationTag as String: privateKeyTag
        ]
        
        let publicKeyAttr : [String: Any] = [
            kSecAttrIsPermanent as String: kCFBooleanTrue,
            kSecAttrApplicationTag as String: publicKeyTag
        ]
        
        
        let parameters: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048,
            kSecPrivateKeyAttrs as String : privateKeyAttr,
            kSecPublicKeyAttrs as String: publicKeyAttr
            ]
        
        var publicKey, privateKey: SecKey?
        
        SecKeyGeneratePair(parameters as CFDictionary, &publicKey, &privateKey)
        var privateKeyData: Data?
        
        if #available(iOS 10.0, *) {
            var error:Unmanaged<CFError>?
            if let cfdata = SecKeyCopyExternalRepresentation(privateKey!, &error) {
                privateKeyData = cfdata as Data
            }
        } else {
            let query: [String:Any] = [
                kSecClass as String: kSecClassKey,
                kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                kSecAttrApplicationTag as String: privateKeyTag,
                kSecReturnData as String: kCFBooleanTrue,
            ]
            
            var secureItemValue: AnyObject?
            let statusCode: OSStatus = SecItemCopyMatching(query as CFDictionary, &secureItemValue)
            if let data = secureItemValue as? Data, statusCode == noErr {
                privateKeyData = data
            }
        }
        
        if let data = privateKeyData {
            resolve(data.base64EncodedString())
        } else {
            reject("generateRSAKeyError", "Export privateKey failed.", nil)
        }
        
    }
    
    
    // MARK: - Private helpers
    
    private func generateRandomBytes(_ length: Int) -> String? {
        var keyData = Data(count: length)
        let result = keyData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, keyData.count, $0)
        }
        if result == errSecSuccess {
            return keyData.base64EncodedString()
        } else {
            // in case of failure
            var randomString = ""
            for _ in 0..<length {
                let randomNumber = Int(arc4random_uniform(10))
                randomString += String(randomNumber)
            }
            return randomString.data(using: String.Encoding.utf8)?.base64EncodedString()
        }
    }
    
}
