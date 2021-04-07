//
//  SettingsManager.swift
//  Jotify
//
//  Created by Harrison Leath on 2/6/21.
//

import UIKit

struct Settings {
    var theme: String
    var hasMigrated: Bool
}

class User {
    static var settings: Settings?
    
    //gets the current settings document from Firebase and updates the model
    static func updateSettings() {
        //success should never be nil and settings should never be nil when success is true
        DataManager.retrieveUserSettings { (settings, success) in
            if success! {
                User.settings = settings!
            } else {
                print("Error retrieving settings")
            }
        }
    }
}