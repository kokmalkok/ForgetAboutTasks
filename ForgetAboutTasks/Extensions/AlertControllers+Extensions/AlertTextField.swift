//
//  AlertTextField.swift
//  ForgetAboutTasks
//
//  Created by Константин Малков on 24.03.2023.
//

import UIKit

extension UIViewController{
    
    
    /// This function display alert with textField for getting some parameters and return string(text) value
    /// - Parameters:
    ///   - title: Customise title in AlertController
    ///   - placeholder: Customise placeholder of textField in alertController
    ///   - type: Type of textfields keyboard
    ///   - completion: This closure return text from textField
    func alertTextField(cell title: String,previousTitle: String? = "", placeholder: String, keyboard type: UIKeyboardType, completion: @escaping (String) -> Void) {
        setupHapticMotion(style: .soft)
        let alert = UIAlertController(title: "", message: title, preferredStyle: .alert)
        alert.addTextField(configurationHandler: { [self] textField in
            textField.placeholder = placeholder
            textField.text = previousTitle
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
                guard let text = alert.textFields?.first?.text else {
                    self.alertError(text: "Error value!".localized())
                    return
                }
                if !text.isEmpty {
                    completion(text)
                } else {
                    self.alertError(text: "Enter some value!".localized())
                }
            }
        })
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
        alert.editButtonItem.tintColor = UIColor(named: "calendarHeaderColor")
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneB = UIBarButtonItem(title: "Done".localized(), style: .done, target: self, action: #selector(toolBarDoneButtonTapped))
        doneB.tintColor = UIColor(named: "calendarHeaderColor")
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([flexibleSpace,doneB], animated: isViewAnimated)
        
        alert.textFields?.first?.inputAccessoryView = toolbar

        
        present(alert, animated: isViewAnimated)
    }
    
    @objc func toolBarDoneButtonTapped(){
        view.endEditing(true)
        if let textField = (presentedViewController as? UIAlertController)?.textFields?.first {
            textField.resignFirstResponder()
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField){
        let minHeight:CGFloat = 40
        let contentHeight = textField.sizeThatFits(CGSize(width: textField.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
        textField.snp.updateConstraints { make in
            make.height.greaterThanOrEqualTo(max(minHeight, contentHeight))
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }
    }
}
