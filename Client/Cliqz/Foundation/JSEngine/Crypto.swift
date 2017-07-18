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
        var privateKey: CCRSACryptorRef?
        var publicKey: CCRSACryptorRef?
        
        var status = CCRSACryptorGeneratePair(2048, 65537, &publicKey, &privateKey)
        guard status == noErr else {
            reject("CCRSACryptorGeneratePair", "Generate pair failed with status \(status)", nil)
            return
        }
        
        defer { CCRSACryptorRelease(privateKey) }
        defer { CCRSACryptorRelease(publicKey) }
        
        var privKeyDataLength = 8192
        let privKeyData = NSMutableData(length: privKeyDataLength)!
        
        status = CCRSACryptorExport(privateKey, privKeyData.mutableBytes, &privKeyDataLength)
        guard status == noErr else {
            reject("CCRSACryptorExport", "Export privateKey failed with status \(status)", nil)
            return
        }
        
        privKeyData.length = privKeyDataLength
        resolve(privKeyData.base64EncodedString())
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
