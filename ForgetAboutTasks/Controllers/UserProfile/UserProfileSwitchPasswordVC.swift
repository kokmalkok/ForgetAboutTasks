//
//  UserProfileSwitchPasswordVC.swift
//  ForgetAboutTasks
//
//  Created by Константин Малков on 07.07.2023.
//

import UIKit
import LocalAuthentication
import SnapKit

class UserProfileSwitchPasswordViewController: UIViewController , UITextFieldDelegate{
    
    private var passwordDigits: String = ""
    private var isCheckPassword: Bool
    
    weak var delegate: CheckSuccessSaveProtocol?
    
    init(isCheckPassword: Bool){
        self.isCheckPassword = isCheckPassword
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let passwordLabel: UILabel = {
       let label = UILabel()
        label.textAlignment = .center
        label.text = "Enter code-password"
        label.backgroundColor = .clear
        label.textColor = UIColor(named: "textColor")
        label.font = .systemFont(ofSize: 26, weight: .bold)
        return label
    }()
    
    private let firstTextField :UITextField = {
       let field = UITextField()
        field.isSecureTextEntry = true
        field.textColor = UIColor(named: "textColor")
        field.backgroundColor = UIColor(named: "backgroundColor")
        field.keyboardType = .numberPad
        field.textAlignment = .center
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor(named: "backgroundColor")?.cgColor
        field.layer.cornerRadius = 8
        field.tag = 1
        return field
    }()
    
    private let secondTextField :UITextField = {
       let field = UITextField()
        field.isSecureTextEntry = true
        field.textColor = UIColor(named: "textColor")
        field.backgroundColor = UIColor(named: "backgroundColor")
        field.keyboardType = .numberPad
        field.textAlignment = .center
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor(named: "backgroundColor")?.cgColor
        field.layer.cornerRadius = 8
        field.tag = 2
        return field
    }()
    
    private let thirdTextField :UITextField = {
       let field = UITextField()
        field.isSecureTextEntry = true
        field.textColor = UIColor(named: "textColor")
        field.backgroundColor = UIColor(named: "backgroundColor")
        field.keyboardType = .numberPad
        field.textAlignment = .center
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor(named: "backgroundColor")?.cgColor
        field.layer.cornerRadius = 8
        field.tag = 3
        return field
    }()
    
    private let forthTextField :UITextField = {
       let field = UITextField()
        field.isSecureTextEntry = true
        field.textColor = UIColor(named: "textColor")
        field.backgroundColor = UIColor(named: "backgroundColor")
        field.keyboardType = .numberPad
        field.textAlignment = .center
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor(named: "backgroundColor")?.cgColor
        field.layer.cornerRadius = 8
        field.tag = 4
        return field
    }()
    
    private let confirmPasswordButton: UIButton = {
        let button = UIButton(type: .system)
        button.isHidden = true
        button.isEnabled = false
        button.setImage(UIImage(systemName: "lock.open.fill"), for: .normal)
        button.setImage(UIImage(systemName: "lock.fill"), for: .selected)
        button.configuration = .tinted()
        button.configuration?.imagePlacement = .leading
        button.configuration?.imagePadding = 4
        button.configuration?.title = "Confirm Password"
        button.configuration?.baseBackgroundColor = UIColor(named: "launchBackgroundColor")
        button.configuration?.baseForegroundColor = UIColor(named: "launchBackgroundColor")
        return button
    }()
    
    private let faceIdButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .thin)
        button.isHidden = true
        button.setImage(UIImage(systemName: "faceid")?.withRenderingMode(.alwaysTemplate).withConfiguration(config), for: .normal)
        button.tintColor = UIColor(named: "textColor")
        button.backgroundColor = .clear
        button.imageView?.contentMode = .scaleAspectFit
        button.imageView?.clipsToBounds = true
        return button
    }()
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        if isCheckPassword {
            setupEntryView()
        } else {
            setupRegistrationView()
            setupView()
        }
        
    }

    //MARK: - Target Methods
    @objc private func textDidChangeValue(textField: UITextField){
        guard let text = textField.text?.first, text.isNumber else { return }
        if text.utf16.count == 1 {
            switch textField {
            case firstTextField:
                passwordDigits += firstTextField.text!
                secondTextField.becomeFirstResponder()
                break
            case secondTextField:
                passwordDigits += secondTextField.text!
                thirdTextField.becomeFirstResponder()
                break
            case thirdTextField:
                passwordDigits += thirdTextField.text!
                forthTextField.becomeFirstResponder()
                break
            case forthTextField:
                passwordDigits += forthTextField.text!
                forthTextField.resignFirstResponder()
                confirmPasswordButton.isEnabled = true
                break
            default:
                break
            }
        }
    }
    
    @objc private func didTapConfirmPassword(sender: UIButton) {
        let emailUser = UserDefaults.standard.string(forKey: "userMail") ?? "No email"
        let passwordData = passwordDigits.data(using: .utf8) ?? Data()
        let data = KeychainManager.get(service: "Local Password", account: emailUser)
        if passwordDigits.count == 4 {
            confirmPasswordButton.setImage(UIImage(systemName: "lock.fill"), for: .normal)
            confirmPasswordButton.setTitle("Confirmed", for: .normal)
            checkAuthForFaceID { [weak self] success in
                UserDefaults.standard.setValue(success, forKey: "accessToFaceID")
                UserDefaults.standard.setValue(true, forKey: "isPasswordCodeEnabled")
                if data != nil {
                    KeychainManager.delete()
                }
                
                try! KeychainManager.save(service: "Local Password", account: emailUser, password: passwordData)
                self?.delegate?.isSavedCompletely(boolean: true)
                self?.navigationController?.popToRootViewController(animated: true)
            }
        } else {
            alertError(text: "Fill all 4 text fields", mainTitle: "Error!".localized())
        }
    }
    @objc private func didTapActiveFaceID(){
        safetyEnterApplicationWithFaceID(textField: firstTextField)
    }
    
    //MARK: - Setups for view
    private func setupView(){
//        UINavigationController.setNavigationBarHidden(self) = 
        setupTextField()
        addConstrains()
        view.backgroundColor = UIColor(named: "calendarHeaderColor")
        confirmPasswordButton.addTarget(self, action: #selector(didTapConfirmPassword(sender: )), for: .touchUpInside)
    }
    
    private func setupRegistrationView(){
        firstTextField.becomeFirstResponder()
        confirmPasswordButton.isHidden = false
    }
    
    private func setupEntryView(){
        confirmPasswordButton.isHidden = true
        faceIdButton.isHidden = false
        faceIdButton.addTarget(self, action: #selector(didTapActiveFaceID), for: .touchUpInside)
        addConstrains()
        setupTextField()
        confirmPasswordButton.isHidden = true
        safetyEnterApplicationWithFaceID(textField: firstTextField)
    }
    
    private func setupTextField(){
        
        firstTextField.delegate = self
        secondTextField.delegate = self
        thirdTextField.delegate = self
        forthTextField.delegate = self
        firstTextField.addTarget(self, action: #selector(textDidChangeValue(textField: )), for: UIControl.Event.editingChanged)
        secondTextField.addTarget(self, action: #selector(textDidChangeValue(textField: )), for: UIControl.Event.editingChanged)
        thirdTextField.addTarget(self, action: #selector(textDidChangeValue(textField: )), for: UIControl.Event.editingChanged)
        forthTextField.addTarget(self, action: #selector(textDidChangeValue(textField: )), for: UIControl.Event.editingChanged)
        
    }
    //MARK: - Keychain safety func for password
    private func safetyEnterApplication(password: String){
        let emailUser = UserDefaults.standard.string(forKey: "userMail") ?? "No email"
        guard let data = KeychainManager.get(service: "Local Password", account: emailUser) else { return }
        let passwordKeyChain = String(decoding: data, as: UTF8.self)
        if passwordKeyChain == password {
            self.dismiss(animated: true)
            UserDefaults.standard.setValue(true, forKey: "isUserConfirmPassword")
        } else {
            alertError(text: "Incorrect password.\nTry again later", mainTitle: "Error!".localized())
        }
    }
    
    
    
    private func checkCorrectPassword(textField: UITextField){
        let emailUser = UserDefaults.standard.string(forKey: "userMail") ?? "No email"
        let value = KeychainManager.get(service: "Local Password", account: emailUser)
        let textValue = String(decoding: value ?? Data(), as: UTF8.self)
        if textField.tag == 4 && !UserDefaults.standard.bool(forKey: "isUserConfirmPassword"){
            if textValue.contains(passwordDigits){
                UserDefaults.standard.setValue(true, forKey: "isUserConfirmPassword")
                showAlertForUser(text: "Success", duration: .now()+1, controllerView: view)
                DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                    self.dismiss(animated: true)
                }
            } else {
                alertError(text: "Incorrect password.Please try again!",mainTitle: "Error")
                clearRequest()
            }
        }
    }
    
    private func clearRequest(){
        firstTextField.text = ""
        secondTextField.text = ""
        thirdTextField.text = ""
        forthTextField.text = ""
        passwordDigits = ""
    }
    
    //MARK: - UITextField Delegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let digit = textField.text,
           
           !digit.isEmpty {
            passwordDigits += digit
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        if isCheckPassword {
            checkCorrectPassword(textField: textField)
        }
    }
}
//MARK: - snapkit constraints
extension UserProfileSwitchPasswordViewController {
    private func addConstrains(){
        let textFieldSubViews = [firstTextField,secondTextField,thirdTextField,forthTextField]
        let stackView = UIStackView(arrangedSubviews: textFieldSubViews)
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.contentMode = .scaleAspectFit
        stackView.axis = .horizontal
        stackView.spacing = 10
        
        
        
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(240)
            make.height.equalTo(50)
        }
        
        view.addSubview(passwordLabel)
        passwordLabel.snp.makeConstraints { make in
            make.bottom.equalTo(stackView.snp.top).offset(-50)
            make.leading.trailing.equalToSuperview().inset(50)
            make.height.equalTo(55)
        }
        
        view.addSubview(confirmPasswordButton)
        confirmPasswordButton.snp.makeConstraints { make in
            make.top.equalTo(stackView.snp.bottom).offset(50)
            make.leading.trailing.equalToSuperview().inset(80)
            make.height.equalTo(50)
        }
        
        view.addSubview(faceIdButton)
        faceIdButton.snp.makeConstraints { make in
            make.top.equalTo(stackView.snp.bottom).offset(50)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(view.frame.size.width/4)
        }
        
        
        
    }
}

