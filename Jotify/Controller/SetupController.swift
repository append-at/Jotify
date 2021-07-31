//
//  InitialSetupController.swift
//  Jotify
//
//  Created by Harrison Leath on 7/9/21.
//

import WidgetKit
import UIKit
import SPPermissions

class SetupController {
    
    public var isNotificationAuthorized: Bool {
        return SPPermissions.Permission.notification.authorized
    }
    
    //setup URL for widgets
    private func setupWidget() {
        GroupDataManager.writeData(path: "recentNoteColor", content: "systemBlue")
        GroupDataManager.writeData(path: "recentNoteContent", content: "This is a placeholder note until you start writing.")
        GroupDataManager.writeData(path: "recentNoteDate", content: "July 2, 2002")
        GroupDataManager.writeData(path: "recentNoteID", content: "no id")
        print("Setting up widgets...")
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    //default Userdefaults
    private func setupDefaults() {
        UserDefaults.standard.register(defaults: [
            "hasMigrated": false,
            "multilineInputEnabled": false,
            "useHaptics": true,
            "deleteOldNotes": false
        ])
    }
    
    //update widget whenever the most recent note changes
    //but do not force refresh the widget if the most recent note has not changed
    public static func updateWidget(note: FBNote) {
        let content = GroupDataManager.readData(path: "recentNoteContent")
        if content != note.content {
            GroupDataManager.writeData(path: "recentNoteDate", content: note.timestamp.getDate())
            GroupDataManager.writeData(path: "recentNoteContent", content: note.content)
            GroupDataManager.writeData(path: "recentNoteColor", content: note.color)
            GroupDataManager.writeData(path: "recentNoteID", content: note.id)
            if #available(iOS 14.0, *) {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
    
    public func handleApplicationSetup() {
        let defaults = UserDefaults.standard
        let shortVersionKey = "CFBundleShortVersionString"
        guard let currentVersion = Bundle.main.infoDictionary![shortVersionKey] as? String else {
            print("Current version could not be found")
            return
        }
        let previousVersion = defaults.object(forKey: shortVersionKey) as? String
        if previousVersion == currentVersion {
            // same version, no update
            print("same version")
            
        } else {
            if previousVersion != nil {
                // new version
                print("new version")
                setupWidget()
                setupDefaults()
                
            } else {
                // first launch
                print("first launch")
                setupWidget()
                setupDefaults()
            }
            defaults.set(currentVersion, forKey: shortVersionKey)
        }
    }
    
}