//
//  Authentication.swift
//  memri
//
//  Created by Ruben Daniels on 7/26/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import LocalAuthentication

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
    
    static func authenticateOwner(_ callback: @escaping (Error?, Bool) -> Void) {
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
            
            localAuthenticationContext.evaluatePolicy(
                LAPolicy.deviceOwnerAuthentication,
                localizedReason: reason
            ) { (success, evaluationError) in
                
                if success {
                    callback(nil, true)
                } else {
                    #warning("Log all errors in the database")
//                    if let errorObj = evaluationError {
//                        let messageToDisplay = self.getErrorDescription(errorCode: errorObj._code)
//                        print(messageToDisplay)
//                    }
                    
                    callback(evaluationError, false)
                }
            }
              
        } else {
            callback("User has not enrolled into using Biometrics", false)
        }
    }
    
    static func installRootKey(areYouSure:Bool, _ callback: @escaping (Error?) -> Void) {
        guard areYouSure == true else {
            callback("This is a destructive operation and user must agree")
            return
        }
        
        let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            .privateKeyUsage,
            nil
        )
        
        if let access = access {
            let attributes: [String: Any] = [
                kSecAttrKeyType as String: kSecAttrKeyTypeEC,
                kSecAttrKeySizeInBits as String: 256,
                kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
                kSecPrivateKeyAttrs as String: [
                    kSecAttrIsPermanent as String: true,
                    kSecAttrApplicationTag as String: RootKeyTag,
                    kSecAttrAccessControl as String: access
                ]
            ]
            
            // TODO: delete previous key with that tag???
            
            var error: Unmanaged<CFError>?
            if let _ = SecKeyCreateRandomKey(attributes as CFDictionary, &error) {
                callback(nil)
            }
            else {
                // TODO Error Handling
//                throw error!.takeRetainedValue() as Error
            }
        }
        else {
            // TODO error handling
        }
    }
    
    static func getPublicRootKey(_ callback: @escaping (Error?, Data?) -> Void) throws {
        do {
            let publicKey = try getPublicRootKeySync()
            callback(nil, publicKey)
        }
        catch {
            //TODO error handling
            callback(error, nil)
        }
    }
    
    static func getPublicRootKeySync() throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: RootKeyTag,
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecReturnRef as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            // TODO Error handling
            throw "Unable to get public key"
        }
        
        let privateKey = item as! SecKey
        let publicKey = SecKeyCopyPublicKey(privateKey)
        
        return publicKey
        
    }
    
    static func generateOwnerAndDBKey(_ callback: @escaping (Error?) -> Void) {
        
    }
    
    static func setOwnerAndDBKey(ownerKey:String, databaseKey:String, _ callback: @escaping (Error?) -> Void) {
        
    }
    
    static func getOwnerAndDBKey(_ callback: @escaping (Error?, String, String) -> Void) {
        
    }
}
