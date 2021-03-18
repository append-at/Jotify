//
//  UIViewController+Extensions.swift
//  Jotify
//
//  Created by Harrison Leath on 1/18/21.
//

import UIKit
import AudioToolbox

extension UIViewController {
    //play haptic feedback from any viewcontroller
    func playHapticFeedback() {
        // iPhone 7 and newer
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    //add gesture recognizer to hide keyboard when view is tapped
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    //set a new rootViewController with animation
    //**crashes when changing between light and dark mode bc
    //keywindow returns nil on force unwrapped instance of window
    func setRootViewController(duration: Double, vc: UIViewController) {
        let window = UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .map({$0 as? UIWindowScene})
            .compactMap({$0})
            .first?.windows
            .filter({$0.isKeyWindow}).first
        
        window?.rootViewController = vc
        window?.makeKeyAndVisible()
        UIView.transition(with: window!, duration: duration, options: .transitionCrossDissolve, animations: nil, completion: nil)
    }
    
    //gets the current rootViewController from connected scenes
    //**can crash under untested conditions due to force unwrap of window
    func getRootViewController() -> UIViewController {
        return (UIApplication.shared.connectedScenes
                    .filter({$0.activationState == .foregroundActive})
                    .map({$0 as? UIWindowScene})
                    .compactMap({$0})
                    .first?.windows
                    .filter({$0.isKeyWindow}).first?.rootViewController)!
    }
    
    
    //change StatusBarStyle in parent, PageViewController
    //override and always make style light if in dark mode
    //**only call this method when PageViewController is present**
    func handleStatusBarStyle(style: UIStatusBarStyle) {
        let rootVC = UIApplication.shared.windows.first!.rootViewController as! PageViewController
        if traitCollection.userInterfaceStyle == .dark {
            rootVC.statusBarStyle = .lightContent
        } else {
            rootVC.statusBarStyle = style
        }
        rootVC.setNeedsStatusBarAppearanceUpdate()
    }
}
