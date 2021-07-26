//
//  UINavigationController+Extensions.swift
//  Jotify
//
//  Created by Harrison Leath on 2/1/21.
//

import UIKit

extension UINavigationController {
    
    func configure(bgColor: UIColor) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = bgColor
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor : bgColor.isDarkColor ? UIColor.white : .black]
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = navigationBar.standardAppearance
    }
}
