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
        
        // 여기서부터 추가된 내용
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if #available(iOS 14, *) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    switch status {
                    case .authorized:
                        print("ATT 권한이 허용되었습니다.")
                    case .denied:
                        print("ATT 권한이 거부되었습니다.")
                    case .notDetermined:
                        print("ATT 권한이 결정되지 않았습니다.")
                    case .restricted:
                        print("ATT 권한이 제한되었습니다.")
                    @unknown default:
                        print("알 수 없는 ATT 권한 상태입니다.")
                    }
                }
            }
        }
        // 여기서부터 추가된 내용 끝
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        // 여기서부터 추가된 내용
        if let incomingUrl = userActivity.webpageURL {
            print("Incoming URL is \(incomingUrl)")
            let isHandled = Airbridge.handleDeeplink(userActivity: userActivity) { url in
                // 딥링크 URL을 처리하는 로직을 여기에 구현합니다.
                print("Deeplink URL: \(url)")
                // 예: 특정 화면으로 이동
                // self.navigateToScreen(with: url)
            } onFailure: { error in
                print("Deeplink handling failed: \(error.localizedDescription)")
            }
            
            if !isHandled {
                // Airbridge 딥링크가 아닌 경우 처리할 로직
                print("Not an Airbridge deeplink")
            }
        }
        // 여기서부터 추가된 내용 끝
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        // 여기서부터 추가된 내용
        guard let url = URLContexts.first?.url else { return }
        
        let isHandled = Airbridge.handleDeeplink(url: url) { url in
            // 딥링크 URL을 처리하는 로직을 여기에 구현합니다.
            print("Deeplink URL: \(url)")
            // 예: 특정 화면으로 이동
            // self.navigateToScreen(with: url)
        } onFailure: { error in
            print("Deeplink handling failed: \(error.localizedDescription)")
        }
        
        if !isHandled {
            // Airbridge 딥링크가 아닌 경우 처리할 로직
            maybePressedRecentNoteWidget(urlContexts: URLContexts)
        }
        // 여기서부터 추가된 내용 끝
    }

    // 여기서부터 추가된 내용
    func handleDeferredDeeplink() {
        let isHandled = Airbridge.handleDeferredDeeplink { url in
            if let url = url {
                // 지연된 딥링크 URL을 처리하는 로직을 여기에 구현합니다.
                print("Deferred Deeplink URL: \(url)")
                // 예: 특정 화면으로 이동
                // self.navigateToScreen(with: url)
            } else {
                print("No deferred deeplink available")
            }
        } onFailure: { error in
            print("Deferred deeplink handling failed: \(error.localizedDescription)")
        }
        
        if !isHandled {
            print("Deferred deeplink not handled or SDK not initialized")
        }
    }
    // 여기서부터 추가된 내용 끝

    // ... 나머지 코드는 그대로 유지
}
