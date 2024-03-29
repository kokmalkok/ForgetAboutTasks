//
//  AlertPhoneNumber.swift
//  ForgetAboutTasks
//
//  Created by Константин Малков on 07.06.2023.
//

import UIKit


extension UIViewController {
    
    
    /// Function for presenting alert controller with entering phone number
    /// - Parameters:
    ///   - title: title of alert header
    ///   - placeholder: placeholder text
    ///   - type: type of keyboard
    ///   - completion: return inputed string  
    func alertPhoneNumber(cell title: String,placeholder: String,keyboard type: UIKeyboardType, completion: @escaping (String) -> Void) {
        setupHapticMotion(style: .soft)
        let alert = UIAlertController(title: "", message: title, preferredStyle: .alert)
        alert.addTextField(configurationHandler: { [self] textField in
            textField.placeholder = placeholder
            textField.clearButtonMode = .whileEditing
            textField.keyboardType = type
            textField.resignFirstResponder()
            textField.returnKeyType = .continue
            
            if type == .default {
                textField.autocapitalizationType = .sentences
                textField.autocorrectionType = .yes
            } else {
                textField.autocapitalizationType = .none
                textField.autocorrectionType = .no
            }
            textField.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(64)
                make.leading.trailing.equalToSuperview().inset(16)
                make.height.greaterThanOrEqualTo(30)
            }
            textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        })
        let saveAction = UIAlertAction(title: "Save".localized(), style: .default,handler: { _ in
            DispatchQueue.main.async {
                guard var text = alert.textFields?.first?.text else {
                    self.alertError(text: "Error value!".localized())
                    return
                }
                if text.count == 11 {
                    if text.first == "7" {
                        text = String.format(with: "+XXXXXXXXXXX", phone: text)
                        completion(text)
                    } else if text.first != "7"{
                        text.replaceSubrange(...text.startIndex, with: "+7")
                        completion(text)
                    }
                } else if text.count == 7{
                    completion(text)
                } else {
                    self.alertError(text: "Please enter a valid phone number with 7 or 10 digits".localized())
                }
            }
        })
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
        alert.editButtonItem.tintColor = UIColor(named: "calendarHeaderColor")
        
        present(alert, animated: isViewAnimated)
    }
}
