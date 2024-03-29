//
//  UIFont+Extensions.swift
//  ForgetAboutTasks
//
//  Created by Константин Малков on 20.07.2023.
//

import UIKit

extension UIFont {
    
    
    /// Function for setting up custom font of app. It Inherit value from UserDefaults and set to all parameters
    /// - Parameter size: font size value if it necessary
    /// - Returns: return converted and updated UIFont format
    static func setMainLabelFont(value size: CGFloat = 1.0) -> UIFont {
        let fontSize = CGFloat(UserDefaults.standard.float(forKey: "fontSizeChanging"))
        let fontName = UserDefaults.standard.string(forKey: "fontNameChanging") ?? "Dilot"
        let fontWeight: CGFloat? = CGFloat(UserDefaults.standard.float(forKey: "fontWeightChanging"))
        var font: UIFont = UIFont()
        if fontWeight == 0.0 {
            font = UIFont(name: fontName, size: fontSize * size) ?? .systemFont(ofSize: fontSize * size)
        } else {
            font = .systemFont(ofSize: fontSize * size, weight: UIFont.Weight(fontWeight ?? 0.0))
        }
        return font
    }
    
    /// This using for subtitles and using custom font size and font type
    /// - Returns: return full formatted UIFont
    static func setDetailLabelFont() -> UIFont {
        let fontSize = CGFloat(UserDefaults.standard.float(forKey: "fontSizeChanging"))
        let fontName = UserDefaults.standard.string(forKey: "fontNameChanging") ?? "Dilot"
        let font: UIFont = UIFont(name: fontName, size: fontSize * 0.7) ?? .systemFont(ofSize: fontSize * 0.7)
        return font
    }
}
