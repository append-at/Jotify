//
//  AppDelegate.swift
//  Jotify
//
//  Created by Harrison Leath on 1/16/21.
//

import UIKit
import Firebase
import CoreData
import AuthenticationServices
// 여기서부터 추가된 내용
import Airbridge
// 여기서부터 추가된 내용 끝

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        
        //check to see if Apple credential revoked since last launch
        didAppleIDStateRevokeWhileTerminated()
        
        //register notification types to be handled when interacted with
        registerNotificationActions()
        
        //Start observing payment transaction updates
        IAPManager.shared.startObserving()
        
        // 여기서부터 추가된 내용
        let option = AirbridgeOptionBuilder(name: "duckeeandroiddev", token: "3b008fdeedf341429314b4b14105fd38")
            .build()
        Airbridge.initializeSDK(option: option)
        // 여기서부터 추가된 내용 끝
        
        return true
    }
    
    // ... 나머지 코드는 그대로 유지
}
