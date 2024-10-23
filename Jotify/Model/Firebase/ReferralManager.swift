//
//  ReferralManager.swift
//  Jotify
//
//  Created by Harrison Leath on 5/20/22.
//

import FirebaseAuth
import FirebaseFirestore
import Airbridge

class ReferralManager {
    func createReferralLink() {
        let uid = AuthManager().uid
        let referralLink = "jotify://referral?invitedby=\(uid)"
        
        User.settings?.referralLink = referralLink
        
        DataManager.updateUserSettings(setting: "referralLink", value: referralLink) { success in
            if !success! {
                print("Error creating and uploading referralLink to firestore")
            }
        }
    }
    
    func grantReferralCredit(referrerId: String) {
        print("Adding referral credits")
        
        DataManager.updateUserSettings(setting: "referrals", value: (User.settings?.referrals ?? 0) + 1) { success in
            if !success! {
                print("Error granting referral credit")
            }
        }
        
        var referrerValue: Int = 0
        
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(referrerId)
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                referrerValue = document.get("referrals") as? Int ?? 0
                
                db.collection("users").document(referrerId).updateData([
                    "referrals": referrerValue + 1,
                ]) { error in
                    if let error = error {
                        print("Error adding document: \(error)")
                    }
                }
            } else {
                print("Document does not exist")
            }
        }
    }
}