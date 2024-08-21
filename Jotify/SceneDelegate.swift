//
//  SceneDelegate.swift
//  Jotify
//
//  Created by Harrison Leath on 1/16/21.
//

import UIKit
import SwiftUI
// 여기서부터 삭제된 내용
// import FirebaseDynamicLinks
// 여기서부터 삭제된 내용 끝
// 여기서부터 추가된 내용
import Airbridge
// 여기서부터 추가된 내용 끝

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        
        UNUserNotificationCenter.current().delegate = self
                
        //handle initial setup from dedicated controller
        SetupController().handleApplicationSetup()
                
        //check if user is logged in
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
        
        //pull up recent note widget launched app
        maybePressedRecentNoteWidget(urlContexts: connectionOptions.urlContexts)
        
        guard let _ = (scene as? UIWindowScene) else { return }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        //check if user is logged in
        if !AuthManager().uid.isEmpty {
            print("logged in")
            if UserDefaults.standard.bool(forKey: "useBiometrics") {
                let poc = PrivacyOverlayController()
                poc.modalPresentationStyle = .fullScreen
                window?.rootViewController?.present(poc, animated: false, completion: nil)
            }
        }
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        ReminderController().renumberBadgesOfPendingNotifications()
        
        //Stop observing payment transaction updates
        IAPManager.shared.stopObserving()
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        // 여기서부터 추가된 내용
        let isHandled = Airbridge.handleDeeplink(userActivity: userActivity) { url in
            // 딥링크 URL을 처리하는 로직을 여기에 구현합니다.
            // 예: 특정 뷰 컨트롤러로 이동
            self.navigateToAppropriateViewController(with: url)
        }
        
        if !isHandled {
            // Airbridge가 처리하지 않은 경우, 기존의 딥링크 처리 로직을 여기에 구현합니다.
        }
        // 여기서부터 추가된 내용 끝
    }
    
    //App opened from background - used partially for widgets
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        
        // 여기서부터 추가된 내용
        let isHandled = Airbridge.handleDeeplink(url: url) { url in
            // 딥링크 URL을 처리하는 로직을 여기에 구현합니다.
            // 예: 특정 뷰 컨트롤러로 이동
            self.navigateToAppropriateViewController(with: url)
        }
        
        if !isHandled {
            // Airbridge가 처리하지 않은 경우, 기존의 URL 처리 로직을 여기에 구현합니다.
            maybePressedRecentNoteWidget(urlContexts: URLContexts)
        }
        // 여기서부터 추가된 내용 끝
    }
    
    // 여기서부터 추가된 내용
    private func navigateToAppropriateViewController(with url: URL) {
        // URL을 파싱하여 적절한 뷰 컨트롤러로 이동하는 로직을 구현합니다.
        // 예: url.path를 확인하여 노트 상세 페이지, 설정 페이지 등으로 이동
    }
    // 여기서부터 추가된 내용 끝
    
    //collect data and present EditingController if widget pressed
    private func maybePressedRecentNoteWidget(urlContexts: Set<UIOpenURLContext>) {
        guard let _: UIOpenURLContext = urlContexts.first(where: { $0.url.scheme == "recentnotewidget-link" }) else { return }
        print("🚀 Launched from widget")
        
        //read data from GroupDataManager then create FBNote object
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
    
    //app terminated when user interacts with notification
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        openNoteFromNotification(userInfo: userInfo)
        completionHandler(UIBackgroundFetchResult.noData)
    }
    
    //app in background when user interacts with notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        if response.notification.request.content.categoryIdentifier ==
            "NOTE_REMINDER" {
            openNoteFromNotification(userInfo: userInfo)
        }
        else {
            // Handle other notification types...
        }
        completionHandler()
    }
    
    //app in foreground when user interacts with notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        //show an alert at top of screen while application is open
        completionHandler(UNNotificationPresentationOptions.alert)
    }
    
    func openNoteFromNotification(userInfo: [AnyHashable : Any]) {
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

