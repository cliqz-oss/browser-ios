/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Alamofire
import Shared
import Foundation
import FxA
import Deferred

public let FxAClientErrorDomain = "org.mozilla.fxa.error"
public let FxAClientUnknownError = NSError(domain: FxAClientErrorDomain, code: 999,
    userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])

let KeyLength: Int = 32

public struct FxALoginResponse {
    public let remoteEmail: String
    public let uid: String
    public let verified: Bool
    public let sessionToken: NSData
    public let keyFetchToken: NSData

    init(remoteEmail: String, uid: String, verified: Bool, sessionToken: NSData, keyFetchToken: NSData) {
        self.remoteEmail = remoteEmail
        self.uid = uid
        self.verified = verified
        self.sessionToken = sessionToken
        self.keyFetchToken = keyFetchToken
    }
}

public struct FxAKeysResponse {
    let kA: NSData
    let wrapkB: NSData

    init(kA: NSData, wrapkB: NSData) {
        self.kA = kA
        self.wrapkB = wrapkB
    }
}

public struct FxASignResponse {
    public let certificate: String

    init(certificate: String) {
        self.certificate = certificate
    }
}

// fxa-auth-server produces error details like:
//        {
//            "code": 400, // matches the HTTP status code
//            "errno": 107, // stable application-level error number
//            "error": "Bad Request", // string description of the error type
//            "message": "the value of salt is not allowed to be undefined",
//            "info": "https://docs.dev.lcip.og/errors/1234" // link to more info on the error
//        }

public enum FxAClientError {
    case Remote(RemoteError)
    case Local(NSError)
}

// Be aware that string interpolation doesn't work: rdar://17318018, much good that it will do.
extension FxAClientError: MaybeErrorType {
    public var description: String {
        switch self {
        case let .Remote(error):
            let errorString = error.error ?? NSLocalizedString("Missing error", comment: "Error for a missing remote error number")
            let messageString = error.message ?? NSLocalizedString("Missing message", comment: "Error for a missing remote error message")
            return "<FxAClientError.Remote \(error.code)/\(error.errno): \(errorString) (\(messageString))>"
        case let .Local(error):
            return "<FxAClientError.Local Error Domain=\(error.domain) Code=\(error.code) \"\(error.localizedDescription)\">"
        }
    }
}

public struct RemoteError {
    let code: Int32
    let errno: Int32
    let error: String?
    let message: String?
    let info: String?

    var isUpgradeRequired: Bool {
        return errno == 116 // ENDPOINT_IS_NO_LONGER_SUPPORTED
            || errno == 117 // INCORRECT_LOGIN_METHOD_FOR_THIS_ACCOUNT
            || errno == 118 // INCORRECT_KEY_RETRIEVAL_METHOD_FOR_THIS_ACCOUNT
            || errno == 119 // INCORRECT_API_VERSION_FOR_THIS_ACCOUNT
    }

    var isInvalidAuthentication: Bool {
        return code == 401
    }

    var isUnverified: Bool {
        return errno == 104 // ATTEMPT_TO_OPERATE_ON_AN_UNVERIFIED_ACCOUNT
    }
}

public class FxAClient10 {
    let URL: NSURL

    public init(endpoint: NSURL? = nil) {
        self.URL = endpoint ?? ProductionFirefoxAccountConfiguration().authEndpointURL
    }

    public class func KW(kw: String) -> NSData? {
        return ("identity.mozilla.com/picl/v1/" + kw).utf8EncodedData
    }

    /**
     * The token server accepts an X-Client-State header, which is the
     * lowercase-hex-encoded first 16 bytes of the SHA-256 hash of the
     * bytes of kB.
     */
    public class func computeClientState(kB: NSData) -> String? {
        if kB.length != 32 {
            return nil
        }
        return kB.sha256.subdataWithRange(NSRange(location: 0, length: 16)).hexEncodedString
    }

    public class func quickStretchPW(email: NSData, password: NSData) -> NSData {
        let salt: NSMutableData = NSMutableData(data: KW("quickStretch")!)
        salt.appendData(":".utf8EncodedData!)
        salt.appendData(email)
        return password.derivePBKDF2HMACSHA256KeyWithSalt(salt, iterations: 1000, length: 32)
    }

    public class func computeUnwrapKey(stretchedPW: NSData) -> NSData {
        let salt: NSData = NSData()
        let contextInfo: NSData = KW("unwrapBkey")!
        let bytes = stretchedPW.deriveHKDFSHA256KeyWithSalt(salt, contextInfo: contextInfo, length: UInt(KeyLength))
        return bytes
    }

    private class func remoteErrorFromJSON(json: JSON, statusCode: Int) -> RemoteError? {
        if json.isError {
            return nil

        }
        if 200 <= statusCode && statusCode <= 299 {
            return nil
        }
        if let code = json["code"].asInt32 {
            if let errno = json["errno"].asInt32 {
                return RemoteError(code: code, errno: errno,
                                   error: json["error"].asString,
                                   message: json["message"].asString,
                                   info: json["info"].asString)
            }
        }
        return nil
    }

    private class func loginResponseFromJSON(json: JSON) -> FxALoginResponse? {
        if json.isError {
            return nil
        }
        
        guard let uid = json["uid"].asString,
            let verified = json["verified"].asBool,
            let sessionToken = json["sessionToken"].asString,
            let keyFetchToken = json["keyFetchToken"].asString else {
                return nil
        }
        
        return FxALoginResponse(remoteEmail: "", uid: uid, verified: verified,
            sessionToken: sessionToken.hexDecodedData, keyFetchToken: keyFetchToken.hexDecodedData)
    }

    private class func keysResponseFromJSON(keyRequestKey: NSData, json: JSON) -> FxAKeysResponse? {
        if json.isError {
            return nil
        }
        if let bundle = json["bundle"].asString {
            let data = bundle.hexDecodedData
            if data.length != 3 * KeyLength {
                return nil
            }
            let ciphertext = data.subdataWithRange(NSMakeRange(0 * KeyLength, 2 * KeyLength))
            let MAC = data.subdataWithRange(NSMakeRange(2 * KeyLength, 1 * KeyLength))

            let salt: NSData = NSData()
            let contextInfo: NSData = KW("account/keys")!
            let bytes = keyRequestKey.deriveHKDFSHA256KeyWithSalt(salt, contextInfo: contextInfo, length: UInt(3 * KeyLength))
            let respHMACKey = bytes.subdataWithRange(NSMakeRange(0 * KeyLength, 1 * KeyLength))
            let respXORKey = bytes.subdataWithRange(NSMakeRange(1 * KeyLength, 2 * KeyLength))

            if ciphertext.hmacSha256WithKey(respHMACKey) != MAC {
                NSLog("Bad HMAC in /keys response!")
                return nil
            }
            if let xoredBytes = ciphertext.xoredWith(respXORKey) {
                let kA = xoredBytes.subdataWithRange(NSMakeRange(0 * KeyLength, 1 * KeyLength))
                let wrapkB = xoredBytes.subdataWithRange(NSMakeRange(1 * KeyLength, 1 * KeyLength))
                return FxAKeysResponse(kA: kA, wrapkB: wrapkB)
            }
        }
        return nil
    }

    private class func signResponseFromJSON(json: JSON) -> FxASignResponse? {
        if json.isError {
            return nil
        }
        if let cert = json["cert"].asString {
            return FxASignResponse(certificate: cert)
        }
        return nil
    }

    lazy private var alamofire: Alamofire.Manager = {
        let ua = UserAgent.fxaUserAgent
        let configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        return Alamofire.Manager.managerWithUserAgent(ua, configuration: configuration)
    }()

    public func login(emailUTF8: NSData, quickStretchedPW: NSData, getKeys: Bool) -> Deferred<Maybe<FxALoginResponse>> {
        let deferred = Deferred<Maybe<FxALoginResponse>>()
        let authPW = quickStretchedPW.deriveHKDFSHA256KeyWithSalt(NSData(), contextInfo: FxAClient10.KW("authPW")!, length: 32)

        let parameters = [
            "email": NSString(data: emailUTF8, encoding: NSUTF8StringEncoding)!,
            "authPW": authPW.base16EncodedStringWithOptions(NSDataBase16EncodingOptions.LowerCase),
        ]

        var URL: NSURL = self.URL.URLByAppendingPathComponent("/account/login")
        if getKeys {
            let components = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false)!
            components.query = "keys=true"
            URL = components.URL!
        }
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.HTTPMethod = Method.POST.rawValue

        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        mutableURLRequest.HTTPBody = JSON(parameters).toString(false).utf8EncodedData

        alamofire.request(mutableURLRequest)
                 .validate(contentType: ["application/json"])
                 .responseJSON { (request, response, result) in

                    // Don't cancel requests just because our Manager is deallocated.
                    withExtendedLifetime(self.alamofire) {
                        if let error = result.error as? NSError {
                            deferred.fill(Maybe(failure: FxAClientError.Local(error)))
                            return
                        }

                        if let data: AnyObject = result.value { // Declaring the type quiets a Swift warning about inferring AnyObject.
                            let json = JSON(data)
                            if let remoteError = FxAClient10.remoteErrorFromJSON(json, statusCode: response!.statusCode) {
                                deferred.fill(Maybe(failure: FxAClientError.Remote(remoteError)))
                                return
                            }

                            if let response = FxAClient10.loginResponseFromJSON(json) {
                                deferred.fill(Maybe(success: response))
                                return
                            }
                        }
                        deferred.fill(Maybe(failure: FxAClientError.Local(FxAClientUnknownError)))
                    }
        }
        return deferred
    }

    public func keys(keyFetchToken: NSData) -> Deferred<Maybe<FxAKeysResponse>> {
        let deferred = Deferred<Maybe<FxAKeysResponse>>()

        let salt: NSData = NSData()
        let contextInfo: NSData = FxAClient10.KW("keyFetchToken")!
        let bytes = keyFetchToken.deriveHKDFSHA256KeyWithSalt(salt, contextInfo: contextInfo, length: UInt(3 * KeyLength))
        let tokenId = bytes.subdataWithRange(NSMakeRange(0 * KeyLength, KeyLength))
        let reqHMACKey = bytes.subdataWithRange(NSMakeRange(1 * KeyLength, KeyLength))
        let keyRequestKey = bytes.subdataWithRange(NSMakeRange(2 * KeyLength, KeyLength))
        let hawkHelper = HawkHelper(id: tokenId.hexEncodedString, key: reqHMACKey)

        let URL = self.URL.URLByAppendingPathComponent("/account/keys")
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.HTTPMethod = Method.GET.rawValue

        let hawkValue = hawkHelper.getAuthorizationValueFor(mutableURLRequest)
        mutableURLRequest.setValue(hawkValue, forHTTPHeaderField: "Authorization")

        alamofire.request(mutableURLRequest)
            .validate(contentType: ["application/json"])
            .responseJSON { (request, response, result) in
                if let error = result.error as? NSError {
                    deferred.fill(Maybe(failure: FxAClientError.Local(error)))
                    return
                }

                if let data: AnyObject = result.value { // Declaring the type quiets a Swift warning about inferring AnyObject.
                    let json = JSON(data)
                    if let remoteError = FxAClient10.remoteErrorFromJSON(json, statusCode: response!.statusCode) {
                        deferred.fill(Maybe(failure: FxAClientError.Remote(remoteError)))
                        return
                    }

                    if let response = FxAClient10.keysResponseFromJSON(keyRequestKey, json: json) {
                        deferred.fill(Maybe(success: response))
                        return
                    }
                }

                deferred.fill(Maybe(failure: FxAClientError.Local(FxAClientUnknownError)))
            }
        return deferred
    }

    public func sign(sessionToken: NSData, publicKey: PublicKey) -> Deferred<Maybe<FxASignResponse>> {
        let deferred = Deferred<Maybe<FxASignResponse>>()

        let parameters = [
            "publicKey": publicKey.JSONRepresentation(),
            "duration": NSNumber(unsignedLongLong: OneDayInMilliseconds), // The maximum the server will allow.
        ]

        let salt: NSData = NSData()
        let contextInfo: NSData = FxAClient10.KW("sessionToken")!
        let bytes = sessionToken.deriveHKDFSHA256KeyWithSalt(salt, contextInfo: contextInfo, length: UInt(2 * KeyLength))
        let tokenId = bytes.subdataWithRange(NSMakeRange(0 * KeyLength, KeyLength))
        let reqHMACKey = bytes.subdataWithRange(NSMakeRange(1 * KeyLength, KeyLength))
        let hawkHelper = HawkHelper(id: tokenId.hexEncodedString, key: reqHMACKey)

        let URL = self.URL.URLByAppendingPathComponent("/certificate/sign")
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.HTTPMethod = Method.POST.rawValue

        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        mutableURLRequest.HTTPBody = JSON(parameters).toString(false).utf8EncodedData

        let hawkValue = hawkHelper.getAuthorizationValueFor(mutableURLRequest)
        mutableURLRequest.setValue(hawkValue, forHTTPHeaderField: "Authorization")

        alamofire.request(mutableURLRequest)
            .validate(contentType: ["application/json"])
            .responseJSON { (request, response, result) in
                if let error = result.error as? NSError {
                    deferred.fill(Maybe(failure: FxAClientError.Local(error)))
                    return
                }

                if let data: AnyObject = result.value { // Declaring the type quiets a Swift warning about inferring AnyObject.
                    let json = JSON(data)
                    if let remoteError = FxAClient10.remoteErrorFromJSON(json, statusCode: response!.statusCode) {
                        deferred.fill(Maybe(failure: FxAClientError.Remote(remoteError)))
                        return
                    }

                    if let response = FxAClient10.signResponseFromJSON(json) {
                        deferred.fill(Maybe(success: response))
                        return
                    }
                }

                deferred.fill(Maybe(failure: FxAClientError.Local(FxAClientUnknownError)))
        }
        return deferred
    }
}
