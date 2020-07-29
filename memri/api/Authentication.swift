//
//  Authentication.swift
//  memri
//
//  Created by Ruben Daniels on 7/26/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import LocalAuthentication
import CryptoKit

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
}

class Authentication {
    /*
        TODO:
            - Enable passcode / bio ID to access the app
                - Setting can turn off bio ID
                - Setting can determine timeout to invalidate local login (0 = always ask)
                - Allow user to view and safe their key
                - Allow a user to email an encrypted version of the key to themselves (with password)
            - Create root key in secure enclave and use to encrypt realm DB
            - Store ownerKey and databaseKey in encrypted realm db
     */
    
//    enum BiometricType {
//        case face
//        case touch
//        case none
//    }
//
//    static var biometricType: BiometricType {
//        let localAuthenticationContext = LAContext()
//
//        localAuthenticationContext.biometryType == LABiometryType.faceID
//            ? .face
//            : .touch
//    }
//
//    let hasTouchID = LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
//
//    if(hasTouchID || (error?.code != LAError.touchIDNotAvailable.rawValue)) {
//         print("Touch Id Available in device")
//    }
    
    private static var isOwnerAuthenticated: Bool = false
    
    /// To check that device has secure enclave or not
    public static var hasSecureEnclave: Bool {
        return !isSimulator && hasBiometrics
    }

    /// To Check that this is this simulator
    public static var isSimulator: Bool {
        return TARGET_OS_SIMULATOR == 1
    }

    /// Check that this device has Biometrics features available
    private static var hasBiometrics: Bool {

        //Local Authentication Context
        let localAuthContext = LAContext()
        var error: NSError?

        /// Policies can have certain requirements which, when not satisfied, would always cause
        /// the policy evaluation to fail - e.g. a passcode set, a fingerprint
        /// enrolled with Touch ID or a face set up with Face ID. This method allows easy checking
        /// for such conditions.
        let isValidPolicy = localAuthContext.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics, error: &error)

        guard isValidPolicy == true else {
            if #available(iOS 11, *) {
                return error!.code != LAError.biometryNotAvailable.rawValue
            }
            else {
                return error!.code != LAError.touchIDNotAvailable.rawValue
            }
        }

        return isValidPolicy
    }
    
    private static let RootKeyTag = "memriPrivateKey"
    
    static func getErrorDescription(errorCode: Int) -> String {
        switch errorCode {
        case LAError.authenticationFailed.rawValue:
            return "Authentication was not successful, because user failed to provide valid credentials."
        case LAError.appCancel.rawValue:
            return "Authentication was canceled by application (e.g. invalidate was called while authentication was in progress)."
        case LAError.invalidContext.rawValue:
            return "LAContext passed to this call has been previously invalidated."
        case LAError.notInteractive.rawValue:
            return "Authentication failed, because it would require showing UI which has been forbidden by using interactionNotAllowed property."
        case LAError.passcodeNotSet.rawValue:
            return "Authentication could not start, because passcode is not set on the device."
        case LAError.systemCancel.rawValue:
            return "Authentication was canceled by system (e.g. another application went to foreground)."
        case LAError.userCancel.rawValue:
            return "Authentication was canceled by user (e.g. tapped Cancel button)."
        case LAError.userFallback.rawValue:
            return "Authentication was canceled, because the user tapped the fallback button (Enter Password)."
        default:
            return "Error code \(errorCode) not found"
        }
    }
    
    static func authenticateOwner(_ callback: @escaping (Error?) -> Void) {
        #if targetEnvironment(simulator)
        if DatabaseController.realmTesting {
            isOwnerAuthenticated = true
            callback(nil)
            return
        }
        #endif
        
        let localAuthenticationContext = LAContext()
        localAuthenticationContext.localizedFallbackTitle = "Please use your Passcode"
        
        var authorizationError: NSError?
        let reason = "Authentication is required for you to continue"
        if localAuthenticationContext.canEvaluatePolicy(
            LAPolicy.deviceOwnerAuthentication,
            error: &authorizationError
        ) {
            let biometricType = localAuthenticationContext.biometryType == LABiometryType.faceID
                ? "Face ID"
                : "Touch ID"
            
            print("Supported Biometric type is: \( biometricType )")
            
            localAuthenticationContext.evaluatePolicy (
                LAPolicy.deviceOwnerAuthentication,
                localizedReason: reason
            ) { (success, evaluationError) in
                
                if success {
                    isOwnerAuthenticated = true
                    
                    callback(nil)
                } else {
                    #warning("Log all errors in the database — how?? At next successful login")
//                    if let errorObj = evaluationError {
//                        let messageToDisplay = self.getErrorDescription(errorCode: errorObj._code)
//                        print(messageToDisplay)
//                    }
                    
                    callback(evaluationError)
                }
            }
              
        } else {
            callback("User has not enrolled into using Biometrics")
        }
    }
    
    static func createRootKey(areYouSure:Bool) throws -> Data {
        guard areYouSure == true else {
            throw "This is a destructive operation and user must agree"
        }
        
        let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            .privateKeyUsage, // [.touchIDAny, .privateKeyUsage]
            nil
        )
        
        if let access = access {
            var attributes: [String: Any]
            
            let appTag = "\(RootKeyTag)".data(using: .utf8)! // \(UUID().uuidString)
            
            if hasSecureEnclave {
                attributes = [
                    kSecAttrKeyType as String: kSecAttrKeyTypeEC,
                    kSecAttrKeySizeInBits as String: 256,
                    kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
//                    kSecAttrApplicationTag as String: appTag,
                    kSecPrivateKeyAttrs as String: [
                        kSecAttrIsPermanent as String: true,
                        kSecAttrApplicationTag as String: appTag,
                        kSecAttrAccessControl as String: access
                    ]
                ]
            }
            else {
                attributes = [
                    kSecAttrKeyType as String: kSecAttrKeyTypeEC,
                    kSecAttrKeySizeInBits as String: 256,
                    kSecAttrApplicationTag as String: appTag,
                    kSecAttrIsPermanent as String: true
                ]
            }
            
            var publicKey: SecKey? = nil
            var privateKey: SecKey? = nil
            let err = SecKeyGeneratePair(attributes as NSDictionary, &publicKey, &privateKey)
            if err == errSecSuccess {
                var error: Unmanaged<CFError>?
                guard
                    let publicKey = publicKey,
                    let data = SecKeyCopyExternalRepresentation(publicKey, &error) as Data?
                else {
                    throw error!.takeRetainedValue() as Error
                }
                
                return data
            }
            else {
                throw NSError(domain: NSOSStatusErrorDomain, code: Int(err), userInfo: nil)
            }
        }
        else {
            // TODO error handling
            throw "Unspecified error"
        }
    }
    
    private static var lastRootPublicKey: Data? = nil
    
    static func getPublicRootKey(_ callback: @escaping (Error?, Data?) -> Void) {
        #warning("Possibly cache the result in memory for X time (5 mins?)")
        do {
            guard isOwnerAuthenticated else {
                throw "Not yet authenticated"
            }
            
            if lastRootPublicKey == nil {
                lastRootPublicKey = try getPublicRootKeySync()
            }
            
            callback(nil, lastRootPublicKey)
        }
        catch {
            authenticateOwner { error in
                if let error = error {
                    //TODO error handling
                    callback(error, nil)
                    return
                }
                
                do {
                    callback(nil, try getPublicRootKeySync())
                }
                catch {
                    callback(error, nil)
                }
            }
        }
    }
    
    static func getPublicRootKeySync() throws -> Data {
        guard isOwnerAuthenticated else {
            throw "Not yet authenticated"
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: RootKeyTag,
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecReturnRef as String: true,
            kSecMatchLimit as String: 10000
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            // TODO Error handling
            throw "Unable to fetch public key"
        }
        
        if
            let privateKey = (item as? Array<SecKey>)?.last,
            let publicKey = SecKeyCopyPublicKey(privateKey)
        {
            var error: Unmanaged<CFError>?
            guard let data = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
                throw error!.takeRetainedValue() as Error
            }
            
            return data
        }
        else {
            throw "Unable to fetch public key"
        }
    }
    
    static func createOwnerAndDBKey() throws {
        let dbKey = "\(UUID().uuidString)\(UUID().uuidString)".replace("-", "")
        
        let privateKey = Curve25519.KeyAgreement.PrivateKey()
        let publicKey = privateKey.publicKey
        
        try setOwnerAndDBKey(
            privateKey: privateKey.rawRepresentation.base64EncodedString(),
            publicKey: publicKey.rawRepresentation.base64EncodedString(),
            dbKey: dbKey
        )
    }
    
    static func setOwnerAndDBKey(privateKey:String, publicKey:String, dbKey:String) throws {
        try DatabaseController.tryCurrent(write:true) { realm in
            realm.objects(CryptoKey.self).filter("name = 'memriDBKey'").forEach { key in
                key.active = false
            }
            
            realm.objects(CryptoKey.self).filter("name = 'memriOwnerKey'").forEach { key in
                key.active = false
            }
            
            let myself = try me()
            
            let dbKeyItem = try Cache.createItem(CryptoKey.self, values: [
                "type": "64BytesRandomHex",
                "key": dbKey,
                "name": "memriDBKey",
                "active": true
            ])
            _ = try dbKeyItem.link(myself, type: "owner")
            
            let ownerPrivateKeyItem = try Cache.createItem(CryptoKey.self, values: [
                "type": "ED25519",
                "role": "private",
                "key": privateKey,
                "name": "memriOwnerKey",
                "active": true
            ])
            let ownerPublicKeyItem = try Cache.createItem(CryptoKey.self, values: [
                "type": "ED25519",
                "role": "public",
                "key": publicKey,
                "name": "memriOwnerKey",
                "active": true
            ])
            _ = try ownerPrivateKeyItem.link(myself, type: "owner")
            _ = try ownerPublicKeyItem.link(myself, type: "owner")
            _ = try ownerPrivateKeyItem.link(ownerPublicKeyItem, type: "publicKey")
            _ = try ownerPublicKeyItem.link(ownerPrivateKeyItem, type: "privateKey")
        }
    }
    
    static func getOwnerAndDBKey(_ callback: @escaping (Error?, String?, String?) -> Void) {
        DatabaseController.current { realm in
            let dbQuery = "name = 'memriDBKey' and active = true"
            guard let dbKey = realm.objects(CryptoKey.self).filter(dbQuery).first else {
                callback("Database key is not set", nil, nil)
                return
            }
            
            let query = "name = 'memriOwnerKey' and role = 'public' and active = true"
            guard let ownerKey = realm.objects(CryptoKey.self).filter(query).first else {
                callback("Owner key is not set", nil, nil)
                return
            }
            
            callback(nil, ownerKey.key, dbKey.key)
        }
    }
}
