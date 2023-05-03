//
//  AlertNewName.swift
//  ForgetAboutTasks
//
//  Created by Константин Малков on 28.04.2023.
//

import UIKit

extension UIViewController {
    func alertNewName(title: String,placeholder: String, completion: @escaping (String) -> Void) {
        let alert = UIAlertController(title: "", message: title, preferredStyle: .alert)
        alert.addTextField(configurationHandler: { text in
            text.placeholder = placeholder
        })
        alert.addAction(UIAlertAction(title: "Save", style: .default,handler: { _ in
            DispatchQueue.main.async {
                guard let text = alert.textFields?.first?.text else {
                    self.alertError(text: "Error value!")
                    return
                }
                if !text.isEmpty {
                    completion(text)
                } else {
                    self.alertError(text: "Enter some value!")
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}