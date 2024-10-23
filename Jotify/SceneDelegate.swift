//
//  SceneDelegate.swift
//  Jotify
//
//  Created by Harrison Leath on 1/16/21.
//

import SwiftUI
import UIKit
import Airbridge

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?
    
    private func handleDeepLink(_ url: URL) {
        let urlString = url.absoluteString
        
        if urlString.hasPrefix("jotify://recentnotewidget-link") {
            handleRecentNoteWidget()
        } else if urlString.hasPrefix("jotify://settings") {
            handleSettings(urlString)
        } else if urlString.hasPrefix("jotify://write") {
            presentController(WriteNoteController())
        } else if urlString.hasPrefix("jotify://note") {
            handleNoteEdit(urlString)
        } else {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let queryItems = components.queryItems else { return }
            
            for queryItem in queryItems {
                if queryItem.name == "referralId" {
                    UserDefaults.standard.set(queryItem.value, forKey: "referralId")
                }
            }
        }
    }

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        UNUserNotificationCenter.current().delegate = self

        // handle initial setup from dedicated controller
        SetupController().handleApplicationSetup()

        // check if user is logged in
        if !AuthManager().uid.isEmpty {
            print("logged in")
            setupWindows(scene: scene, vc: PageBoyController())
        } else {
            print("not logged in")
            if SetupController.firstLauch ?? false {
                setupWindows(scene: scene, vc: OnboardingController())
            } else {
                setupWindows(scene: scene, vc: UIHostingController(rootView: SignUpView()))
            }
        }

        if let urlContext = connectionOptions.urlContexts.first {
            Airbridge.trackDeeplink(url: urlContext.url)
            
            let isHandled = Airbridge.handleDeeplink(url: urlContext.url) { url in
                self.handleDeepLink(url)
            }
            
            if !isHandled {
                maybePressedRecentNoteWidget(urlContexts: connectionOptions.urlContexts)
            }
        }
        
        Airbridge.handleDeferredDeeplink { url in
            if let url = url {
                self.handleDeepLink(url)
            }
        }

        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        // check if user is logged in
        if !AuthManager().uid.isEmpty {
            print("logged in")
            if UserDefaults.standard.bool(forKey: "useBiometrics") {
                let poc = PrivacyOverlayController()
                poc.modalPresentationStyle = .fullScreen
                window?.rootViewController?.present(poc, animated: false, completion: nil)
            }
        }
    }

    func sceneDidEnterBackground(_: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        ReminderController().renumberBadgesOfPendingNotifications()

        // Stop observing payment transaction updates
        IAPManager.shared.stopObserving()
    }

    func scene(_: UIScene, continue userActivity: NSUserActivity) {
        Airbridge.trackDeeplink(userActivity: userActivity)
        
        let isHandled = Airbridge.handleDeeplink(userActivity: userActivity) { url in
            self.handleDeepLink(url)
        }
        
        if !isHandled {
            if let incomingUrl = userActivity.webpageURL {
                print("Incoming URL is \(incomingUrl)")
            }
        }
    }

    func scene(_: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let urlContext = URLContexts.first else { return }
        
        Airbridge.trackDeeplink(url: urlContext.url)
        
        let isHandled = Airbridge.handleDeeplink(url: urlContext.url) { url in
            self.handleDeepLink(url)
        }
        
        if !isHandled {
            maybePressedRecentNoteWidget(urlContexts: URLContexts)
        }
    }

    private func handleRecentNoteWidget() {
        let content = GroupDataManager.readData(path: "recentNoteContent")
        let color = GroupDataManager.readData(path: "recentNoteColor")
        let date = GroupDataManager.readData(path: "recentNoteDate")
        let id = GroupDataManager.readData(path: "recentNoteID")

        EditingData.currentNote = FBNote(content: content, timestamp: date.getTimestamp(), id: id, color: color)

        presentController(EditingController())
    }

    private func handleSettings(_ urlString: String) {
        if urlString.hasSuffix("/general") {
            presentController(GeneralSettingsController())
        } else if urlString.hasSuffix("/accounts") {
            presentController(AccountSettingsController())
        } else if urlString.hasSuffix("/referral") {
            presentController(ReferralSettingsController())
        } else if urlString.hasSuffix("/customization") {
            presentController(CustomizationSettingsController())
        } else {
            presentController(MasterSettingsController())
        }
    }

    private func handleNoteEdit(_ urlString: String) {
        let components = urlString.components(separatedBy: "/")
        if components.count >= 3, components[components.count - 2] == "note", components.last == "edit" {
            let noteId = components[components.count - 3]
            EditingData.currentNote = FBNote(content: "", timestamp: Date().timeIntervalSince1970, id: noteId, color: "")
            presentController(EditingController())
        }
    }

    private func presentController(_ controller: UIViewController) {
        let presentable = StatusBarResponsiveNavigationController(rootViewController: controller)
        presentable.modalPresentationStyle = .fullScreen
        window?.rootViewController?.present(presentable, animated: true, completion: nil)
    }

    private func maybePressedRecentNoteWidget(urlContexts: Set<UIOpenURLContext>) {
        guard let _: UIOpenURLContext = urlContexts.first(where: { $0.url.scheme == "recentnotewidget-link" }) else { return }
        print("🚀 Launched from widget")

        // read data from GroupDataManager then create FBNote object
        let content = GroupDataManager.readData(path: "recentNoteContent")
        let color = GroupDataManager.readData(path: "recentNoteColor")
        let date = GroupDataManager.readData(path: "recentNoteDate")
        let id = GroupDataManager.readData(path: "recentNoteID")

        EditingData.currentNote = FBNote(content: content, timestamp: date.getTimestamp(), id: id, color: color)

        let presentable = StatusBarResponsiveNavigationController(rootViewController: EditingController())
        presentable.modalPresentationStyle = .fullScreen

        if !AuthManager().uid.isEmpty {
            print("logged in")
            if !UserDefaults.standard.bool(forKey: "useBiometrics") {
                window?.rootViewController?.present(presentable, animated: true, completion: nil)
            }
        }
    }

    func setupWindows(scene: UIScene, vc: UIViewController) {
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = vc
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    // app terminated when user interacts with notification
    func application(_: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        openNoteFromNotification(userInfo: userInfo)
        completionHandler(UIBackgroundFetchResult.noData)
    }

    // app in background when user interacts with notification
    func userNotificationCenter(_: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        if response.notification.request.content.categoryIdentifier ==
            "NOTE_REMINDER"
        {
            openNoteFromNotification(userInfo: userInfo)
        } else {
            // Handle other notification types...
        }
        completionHandler()
    }

    // app in foreground when user interacts with notification
    func userNotificationCenter(_: UNUserNotificationCenter, willPresent _: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // show an alert at top of screen while application is open
        completionHandler(UNNotificationPresentationOptions.alert)
    }

    func openNoteFromNotification(userInfo: [AnyHashable: Any]) {
        let noteID = userInfo["noteID"] as! String
        let color = userInfo["color"] as! String
        let timestamp = userInfo["timestamp"] as! Double
        let content = userInfo["content"] as! String

        print("NoteID from reminder: \(noteID)")

        EditingData.currentNote = FBNote(content: content, timestamp: timestamp, id: noteID, color: color)

        DataManager.removeReminder(uid: noteID) { success in
            if !success! {
                print("There was an error deleting the reminder")
            } else {
                print("Reminder was succesfully deleted and removed from backend")
                UIApplication.shared.applicationIconBadgeNumber -= 1
            }
        }

        let presentable = StatusBarResponsiveNavigationController(rootViewController: EditingController())
        presentable.modalPresentationStyle = .fullScreen
        window?.rootViewController?.present(presentable, animated: true)
    }
}