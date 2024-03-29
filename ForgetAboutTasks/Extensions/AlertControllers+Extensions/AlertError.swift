//
//  AlertError.swift
//  ForgetAboutTasks
//
//  Created by Константин Малков on 10.04.2023.
//

import UIKit

extension UIViewController {
    
    /// Function for presenting alert controller for displaying error
    /// - Parameters:
    ///   - text: default error value or custom text of subtitle
    ///   - mainTitle: default header of alert controller or custom
    func alertError(text: String = "",mainTitle: String = "Error".localized()){
        setupHapticMotion(style: .medium)
        let alert = UIAlertController(title: mainTitle, message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".localized(), style: .default))
        present(alert, animated: isViewAnimated)
    }
}
