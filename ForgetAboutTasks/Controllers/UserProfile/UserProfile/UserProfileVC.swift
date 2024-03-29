//
//  UserProfileViewController.swift
//  ForgetAboutTasks
//
//  Created by Константин Малков on 09.03.2023.
//

import UIKit
import FirebaseAuth
import SnapKit
import UserNotifications
import EventKit
import LocalAuthentication
import Contacts
import Photos
import GoogleSignIn
import SafariServices

///Structure using for storing title,image and color of image which using in future to displaying in UITableView
struct UserProfileData {
    var title: String
    var cellImage: UIImage
    var cellImageColor: UIColor
}

class UserProfileViewController: UIViewController {
    
    private let infoText = "Authorization goes through a special Firebase Authentication service. User data is not accessible to anyone, including the development team.\nThis application collects data to improve the performance of the application, as well as for better user experience. All data is encrypted and stored on a special server inaccessible to anyone.\nRealm Data Base is used as storage, user settings and other system parameters are stored in UserDefaults.".localized()

    private var cellArray = [[
                        UserProfileData(title: "Dark Mode".localized(),
                                        cellImage: UIImage(systemName: "moon.fill")!,
                                        cellImageColor: .purple),
                        UserProfileData(title: "Access to Notifications".localized(),
                                        cellImage: UIImage(systemName: "bell.square.fill")!,
                                        cellImageColor: .systemRed),
                        UserProfileData(title: "Access to Calendar's Event".localized(),
                                        cellImage: UIImage(systemName: "calendar.badge.clock")!,
                                        cellImageColor: .systemRed),
                        UserProfileData(title: "Access to Contacts".localized(),
                                        cellImage: UIImage(systemName: "character.book.closed.fill")!,
                                        cellImageColor: .systemBrown ),
                        UserProfileData(title: "Access to Photo and Camera".localized(),
                                        cellImage: UIImage(systemName: "camera.circle")!,
                                        cellImageColor: UIColor(named: "textColor")! )
                    ],
                    [
                        UserProfileData(title: "Access to Face ID".localized(),
                                        cellImage: UIImage(systemName: "faceid")!,
                                        cellImageColor: .systemBlue),
                        UserProfileData(title: "Code-password and Face ID".localized(),
                                        cellImage: UIImage(systemName: "lock.open.fill")!,
                                        cellImageColor: .systemBlue),
                        UserProfileData(title: "Password check frequency".localized(),
                                        cellImage: UIImage(systemName: "timer")!,
                                        cellImageColor: .systemIndigo)
                    ],
                    [
                        UserProfileData(title: "Change App Icon".localized(),
                                        cellImage: UIImage(systemName: "app.fill")!,
                                        cellImageColor: .systemIndigo),
                        UserProfileData(title: "Change Font".localized(),
                                        cellImage: UIImage(systemName: "character.cursor.ibeam")!,
                                        cellImageColor: .systemIndigo),
                        UserProfileData(title: "Enable Animation".localized(),
                                        cellImage: UIImage(systemName: "figure.walk.motion")!,
                                        cellImageColor: .systemGreen),
                        UserProfileData(title: "Enable vibration".localized(),
                                        cellImage: UIImage(systemName: "iphone.gen2.radiowaves.left.and.right")!,
                                        cellImageColor: .black)
                     ],
                     [
                        UserProfileData(title: "Language".localized(),
                                        cellImage: UIImage(systemName: "keyboard.fill")!,
                                        cellImageColor: .systemGreen),
                        UserProfileData(title: "Information".localized(),
                                        cellImage: UIImage(systemName: "info.circle.fill")!,
                                        cellImageColor: .systemGray)
                     ],
                     [
                        UserProfileData(title: "Delete Account".localized(),
                                        cellImage: UIImage(systemName: "trash.fill")!,
                                        cellImageColor: .systemRed),
                        UserProfileData(title: "Change Account Password".localized(),
                                        cellImage: UIImage(systemName: "square.and.pencil")!,
                                        cellImageColor: .systemBlue),
                        UserProfileData(title: "Log Out".localized(),
                                        cellImage: UIImage(systemName: "arrow.uturn.right.square.fill")!,
                                        cellImageColor: .systemRed)
                     ]]

    private var passwordBoolean = UserDefaults.standard.bool(forKey: "isPasswordCodeEnabled")
    private let notificationCenter = UNUserNotificationCenter.current()
    private let provider = DataProvider()
    private let eventStore: EKEventStore = EKEventStore()
    private let semaphore = DispatchSemaphore(value: 0)
    private let userInterface = UserDefaultsManager.shared
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let windows = UIApplication.shared.connectedScenes.first?.inputView?.overrideUserInterfaceStyle
    
 //MARK: - UI Elements
    private var imagePicker = UIImagePickerController()
    private let scrollView = UIScrollView()
    private let tableView = UITableView(frame: CGRectZero, style: .insetGrouped)
    
    private let profileView: UIView = {
       let view = UIView()
        view.backgroundColor = #colorLiteral(red: 0.3920767307, green: 0.5687371492, blue: 0.998278439, alpha: 1)
        view.layer.cornerRadius = 8
        return view
    }()
    
    private let userImageView: UIImageView = {
        let image = UIImageView(frame: .zero)
        image.sizeToFit()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.backgroundColor = UIColor(named: "backgroundColor")
        image.layer.masksToBounds = true
        image.clipsToBounds = true
        image.layer.borderWidth = 1.0
        image.layer.borderColor = UIColor(named: "textColor")?.cgColor
        image.image = UIImage(systemName: "photo.circle")
        image.tintColor = .black
        return image
    }()
    
    private let changeUserImageView: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Set image".localized(), for: .normal)
        button.setTitleColor(UIColor(named: "textColor"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .clear
        return button
    }()
    
    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.text = "Press to set name of user".localized()
        label.numberOfLines = 1
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 24, weight: .medium)
        label.backgroundColor = .clear
        label.layer.cornerRadius = 12
        return label
    }()
    
    private let mailLabel: UILabel = {
        let label = UILabel()
        label.text = "User email".localized()
        label.numberOfLines = 1
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 16, weight: .light)
        label.backgroundColor = .clear
        label.layer.cornerRadius = 12
        return label
    }()
    
    private let ageLabel: UILabel = {
        let label = UILabel()
        label.text = "Press to set user's age".localized()
        label.numberOfLines = 1
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 16, weight: .light)
        label.backgroundColor = .clear
        label.layer.cornerRadius = 12
        return label
    }()
 //MARK: - Load cicle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
        setupView()
        tableView.reloadData()
    }
    
    //MARK: - Targets methods
    @objc private func didTapLogout(){
        setupHapticMotion(style: .soft)
        let statusAuth = UserDefaults.standard.bool(forKey: "isAuthorised")
        let alert = UIAlertController(title: "Warning".localized(), message: "Do you want to Exit from your account?".localized(), preferredStyle: .alert)
        let confirm = UIAlertAction(title: "Confirm".localized(), style: .destructive,handler: { [weak self] _ in
            if statusAuth == true {
                do {
                    try FirebaseAuth.Auth.auth().signOut()
                    UserDefaultsManager.shared.signOut()
                    let vc = AuthenticationViewController()
                    vc.navigationItem.hidesBackButton = true
                    self?.navigationController?.pushViewController(vc, animated: isViewAnimated)
                } catch let error {
                    self?.alertError(text: error.localizedDescription)
                }
            } else {
                self?.alertError(text: "Cant exit from account.\nTry again later")
            }
        })
        
        let cancel = UIAlertAction(title: "Cancel".localized(), style: .cancel)

        alert.addAction(confirm)
        alert.addAction(cancel)
        present(alert, animated: isViewAnimated)
    }
    
    
    
    @objc private func didTapImagePicker(){
        setupHapticMotion(style: .soft)
        view.alpha = 0.7
        imagePickerAlertController()
    }
    
    @objc private func didTapOnName(sender: UITapGestureRecognizer){
        setupHapticMotion(style: .soft)
        alertTextField(cell: "Enter new name and second name".localized(), placeholder: "Enter the text".localized(), keyboard: .default) {[weak self] text in
            self?.userNameLabel.text = text
            UserDefaults.standard.set(text, forKey: "userName")
        }
    }
    
    @objc private func didTapOnAge(sender: UITapGestureRecognizer){
        setupHapticMotion(style: .soft)
        alertTextField(cell: "Enter your age".localized(), placeholder: "Enter age number".localized(), keyboard: .numbersAndPunctuation) { [weak self] age in
            self?.ageLabel.text = "Age: ".localized() + age
            UserDefaults.standard.set(age, forKey: "userAge")
        }
    }
    
    @objc private func didTapSwitchDisplayMode(sender: UISwitch){
        let interfaceStyle: UIUserInterfaceStyle = sender.isOn ? .dark : .light
        UIView.animate(withDuration: 0.5) {
            UIApplication.shared.windows.forEach { window in
                window.overrideUserInterfaceStyle = interfaceStyle
                if let _ = window.windowScene?.delegate as? SceneDelegate {
                    UserDefaults.standard.setValue(sender.isOn, forKey: "setUserInterfaceStyle")
                }
            }
        }
    }
    
    @objc private func didTapChangeAccessNotifications(sender: UISwitch){
        DispatchQueue.main.async { [weak self] in
            if !sender.isOn {
                self?.showSettingsForChangingAccess(title: "Switching off access Notifications".localized(), message: "Do you want to switch off notifications?".localized()) { success in
                    if !success {
                        sender.isOn = true
                    } else {
                        sender.isOn = false
                    }
                }
            } else {
                self?.notificationCenter.requestAuthorization(options: [.alert,.badge,.sound]) { success, error in
                    if success {
                        DispatchQueue.main.async {
                            self?.showAlertForUser(text: "Notifications turn on completely".localized(), duration: DispatchTime.now() + 2, controllerView: (self?.view)!)
                            sender.isOn = success
                        }
                    } else {
                        self?.showSettingsForChangingAccess(title: "Switching on Notifications".localized(), message: "Do you want to switch on notifications?".localized()) { success in
                            if !success {
                                sender.isOn = false
                            } else {
                                sender.isOn = true
                            }
                        }
                    }
                }
            }
        }
        
    }
    
    @objc private func didTapChangeAccessCalendar(sender: UISwitch){
        if !sender.isOn {
            showSettingsForChangingAccess(title: "Switching off access Calendar".localized(), message: "Do you want to switch off access to Calendar?".localized()) { success in
                if !success {
                    sender.isOn = true
                }
            }
        } else {
            request(forAllowing: eventStore) { success in
                sender.isOn = success
            }
        }
    }
    
    @objc private func didTapChangeAccessToFaceID(sender: UISwitch){
        DispatchQueue.main.async { [weak self] in
            if !sender.isOn {
                self?.showSettingsForChangingAccess(title: "Switching Off Face ID".localized(), message: "Do you want to switch off access to Face ID. You could always change access if it will be necessary ".localized()) { success in
                    if !success {
                        sender.isOn = true
                    } else {
                        UserDefaults.standard.setValue(false, forKey: "accessToFaceID")
                    }
                }
            } else {
                self?.checkAuthForFaceID { success in
                    if !success {
                        self?.alertError(text: "You need to turn on Face ID in system settings for future use".localized())
                    }
                    sender.isOn = success
                }
            }
        }
    }
    
    @objc private func didTapChangeAccessToContacts(sender: UISwitch){
        DispatchQueue.main.async { [weak self] in
            if !sender.isOn {
                self?.showSettingsForChangingAccess(title: "Switching off access to Contacts".localized(), message: "Do you want to switch off access to Contacts? You could always change access if it will be necessary".localized()) { success in
                    if !success {
                        sender.isOn = true
                    }
                }
            } else {
                self?.checkAuthForContacts { success in
                    sender.isOn = success 
                }
            }
        }
    }
    
    @objc private func didTapChangeAccessToMedia(sender: UISwitch){
        DispatchQueue.main.async { [weak self] in
            if !sender.isOn {
                self?.showSettingsForChangingAccess(title: "Switching off access to Media".localized(), message: "Do you want to switch off access to Media? You could always change access if it will be necessary".localized()) { success in
                    if !success {
                        sender.isOn = true
                    }
                }
            } else {
                
            }
        }
    }
 
    @objc private func didTapDisableAnimation(sender: UISwitch){
        DispatchQueue.main.async {
            UserDefaults.standard.setValue(sender.isOn, forKey: "enabledAnimation")
        }
    }
    
    @objc private func didTapChangeNapticStyle(sender: UISwitch){
        DispatchQueue.main.async {
            UserDefaults.standard.setValue(sender.isOn, forKey: "enableVibration")
        }
    }

    @objc private func didTapDismissView(){
        tabBarController?.tabBar.isHidden = false
    }
    
    
    
    //MARK: - Setup methods
    
    private func setupView(){
        setupNavigationController()
        configureConstraints()
        setupFontSize()
        setupDelegates()
        setupTapGestureForImage()
        setTapGestureForLabel()
        setTapGestureForAgeLabel()
        setupTargets()
        loadingData()
        setupTableView()
        setupLabelUnderline()
        view.backgroundColor = UIColor(named: "backgroundColor")
    }
    //setup methods
    private func setupNavigationController(){
        title = "My Profile".localized()
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.tintColor = UIColor(named: "textColor")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.uturn.right.square"), style: .done, target: self, action: #selector(didTapLogout))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .done, target: self, action: #selector(didTapDismissView))
    }
    
    private func setupFontSize(){
        ageLabel.font = .setMainLabelFont()
        userNameLabel.font = .setMainLabelFont()
        mailLabel.font = .setMainLabelFont()
        changeUserImageView.titleLabel?.font = .setMainLabelFont()
        tableView.reloadData()
    }
    
    private func setupDelegates(){
        imagePicker.delegate = self
    }
    
    private func setupTapGestureForImage(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapImagePicker))
        userImageView.isUserInteractionEnabled = true
        userImageView.addGestureRecognizer(tap)
    }
    
    private func setTapGestureForLabel(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapOnName))
        userNameLabel.isUserInteractionEnabled = true
        userNameLabel.addGestureRecognizer(tap)
    }
    
    private func setTapGestureForAgeLabel(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapOnAge))
        ageLabel.isUserInteractionEnabled = true
        ageLabel.addGestureRecognizer(tap)
    }
    
    private func setupTargets(){
        changeUserImageView.addTarget(self, action: #selector(didTapImagePicker), for: .touchUpInside)
    }
    
    private func loadingData(){
        let (name,mail,age) = UserDefaultsManager.shared.loadData()
        if let url = UserDefaults.standard.url(forKey: "userImageURL"){
            provider.dataProvider(url: url) { [weak self] image in
                let convertedImage = self?.imageWith(image: image ?? UIImage())
                self?.userImageView.image = convertedImage
            }
        } else {
            let image = UserDefaultsManager.shared.loadSettedImage()
            userImageView.image = image
        }
        
        
        mailLabel.text = mail
        ageLabel.text = "Age: ".localized() + age
        userNameLabel.text = name
    }
    
    private func setupTableView(){
        tableView.register(UserProfileTableViewCell.self, forCellReuseIdentifier: UserProfileTableViewCell.identifier)
        tableView.bounces = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.layer.cornerRadius = 8
        tableView.backgroundColor = UIColor(named: "backgroundColor")
        tableView.separatorStyle = .none
        tableView.isUserInteractionEnabled = true
    }
    
    private func setupLabelUnderline(){
        guard let labelText = userNameLabel.text, let ageText = ageLabel.text else { return }
        let attributedText = NSAttributedString(string: labelText, attributes: [NSAttributedString.Key.underlineStyle : NSUnderlineStyle.single.rawValue])
        let attributedText2 = NSAttributedString(string: ageText, attributes: [NSAttributedString.Key.underlineStyle : NSUnderlineStyle.single.rawValue])
        userNameLabel.attributedText = attributedText
        ageLabel.attributedText = attributedText2
        changeUserImageView.titleLabel?.attributedText = attributedText
    }
    //MARK: - User Profile Managers
    
    /// Converting image to correct size which successfully will size in table view cell
    /// - Parameter image: input UIImage
    /// - Returns: return converted size image
    private func imageWith(image: UIImage) -> UIImage {
        let newSize = CGSize(width: image.size.width/2, height: image.size.height/2)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: CGPoint.zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? UIImage(systemName: "square.fill")!
    }
    
    /// Function ask user what exactly he can do with User Image. Return choosed image from media, new taken photo or user could delete and set default image
    private func imagePickerAlertController() {
        let alert = UIAlertController(title: nil, message: "What exactly do you want to do?".localized(), preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Choose image from Photo".localized(), style: .default,handler: { [self] _ in
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
                imagePicker.delegate = self
                imagePicker.sourceType = .photoLibrary
                imagePicker.allowsEditing = true
                activityIndicator.startAnimating()
                view.alpha = 0.6
                present(self.imagePicker, animated: isViewAnimated)
            }
        }))
        alert.addAction(UIAlertAction(title: "Make new image".localized(), style: .default,handler: { [self] _ in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                imagePicker.delegate = self
                imagePicker.sourceType = .camera
                imagePicker.allowsEditing = true
                activityIndicator.startAnimating()
                view.alpha = 0.6
                present(self.imagePicker, animated: isViewAnimated)
            }
        }))
        alert.addAction(UIAlertAction(title: "Delete image".localized(), style: .destructive,handler: { _ in
            self.userImageView.image = UIImage(systemName: "photo.circle")
            UserDefaults.standard.set(nil,forKey: "userImage")
            self.view.alpha = 1
            self.activityIndicator.stopAnimating()
        }))
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel,handler: { _ in
            self.view.alpha = 1
            self.activityIndicator.stopAnimating()
        }))
        present(alert, animated: isViewAnimated)
    }
    
    ///Setup segue to choose application icon image
    private func openSelectionChangeIcon(){
        setupHapticMotion(style: .soft)
        let vc = UserProfileAppIconViewController()
        vc.checkSelectedIcon = { [weak self] value in
            if value == true {
                self?.tableView.reloadData()
            }
        }
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .formSheet
        nav.sheetPresentationController?.detents = [.custom(resolver: { _ in return self.view.frame.size.height/5 })]
        nav.sheetPresentationController?.prefersGrabberVisible = true
        nav.isNavigationBarHidden = false
        present(nav, animated: isViewAnimated)
    }
    
    
    /// Open alert for choosing actions with setting up password for application
    /// - Parameters:
    ///   - title: title of alert controller
    ///   - message: subtitle of alert controller
    ///   - alertTitle: optional. It will display text when user want to turn on password
    private func openPasswordController(title: String = "Code-password".localized(),message: String = "This function allow you to switch on password if it neccesary. Any time you could change it".localized(),alertTitle: String = "Switch on code-password".localized()){
        setupHapticMotion(style: .soft)
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: alertTitle, style: .default,handler: { [unowned self] _ in
            self.passwordBoolean = UserDefaults.standard.bool(forKey: "isPasswordCodeEnabled")
            let vc = UserProfileSwitchPasswordViewController(isCheckPassword: false)
            vc.delegate = self
            navigationController?.pushViewController(vc, animated: isViewAnimated)
        }))
        if passwordBoolean {
            alert.addAction(UIAlertAction(title: "Switch off".localized(), style: .default,handler: { [weak self]_ in
                UserDefaults.standard.setValue(false, forKey: "isPasswordCodeEnabled")
                KeychainManager.shared.delete()
                self?.passwordBoolean = UserDefaults.standard.bool(forKey: "isPasswordCodeEnabled")
                self?.tableView.reloadData()
                
            }))
        }
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
        present(alert, animated: isViewAnimated)
        
    }
    
    /// Open view controller with changing font size,style of all application
    private func openChangeFontController(){
        let vc = ChangeFontViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        nav.sheetPresentationController?.detents = [.large()]
        nav.sheetPresentationController?.prefersGrabberVisible = true
        nav.modalTransitionStyle = .coverVertical
        nav.isNavigationBarHidden = false
        self.present(nav, animated: isViewAnimated) { [unowned self] in
            self.setupView()
            self.tableView.reloadData()
        }
    }
    
    
    /// Open alert controller if user ask to delete application. It delete it from local store and from Firebase. If user login with Google - it will segue to Google mail settings to delete account
    private func deleteAccount(){
        let alertController = UIAlertController(title: "Warning".localized(), message: "Do you want to delete your account?".localized(), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Delete".localized(), style: .destructive,handler: { [weak self] _ in
            let boolean = UserDefaults.standard.bool(forKey: "authWithGoogle")
            guard let user = Auth.auth().currentUser else {
                self?.alertError(text: "Error access to account".localized())
                return }
            if !boolean {
                user.delete { [weak self] error in
                    if let error = error {
                        self?.alertError(text: error.localizedDescription)
                    } else {
                        let alert = UIAlertController(title: nil, message: "Account was deleted".localized(), preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK".localized(), style: .cancel,handler: {_ in
                            UserDefaultsManager.shared.signOut()
                            let vc = AuthenticationViewController()
                            vc.navigationItem.hidesBackButton = true
                            self?.navigationController?.pushViewController(vc, animated: isViewAnimated)
                        }))
                        self?.present(alert, animated: isViewAnimated)
                        
                    }
                }
            } else {
                guard let url = URL(string: "https://myaccount.google.com/deleteaccount") else {
                    self?.alertError(text: "Can't access to link".localized())
                    return
                }
                let vc = SFSafariViewController(url: url)
                self?.navigationController?.pushViewController(vc, animated: isViewAnimated)
            }
            
            }))
        alertController.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
        present(alertController, animated: isViewAnimated)
    }
    
    private func changeAccountPassword(){
        let alert = UIAlertController(title: "Warning".localized(), message: "Do you want to change account password?".localized(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Change".localized(), style: .default,handler: { [weak self] _ in
            let boolean = UserDefaults.standard.bool(forKey: "authWithGoogle")
            guard let user = Auth.auth().currentUser else {
                self?.alertError(text: "Error access to account".localized())
                return
            }

            if !boolean {
                let vc = ChangePasswordViewController(account: user.email ?? "")
                self?.navigationController?.pushViewController(vc, animated: isViewAnimated)
            } else {
                guard let url = URL(string: "https://myaccount.google.com/signinoptions/password") else {
                    self?.alertError(text: "Can't access to link".localized())
                    return
                }
                let vc = SFSafariViewController(url: url)
//                vc.tabBarController?.tabBar.isHidden = true
                vc.delegate = self
                self?.present(vc, animated: true,completion: {
                    self?.tabBarController?.tabBar.isHidden = true
                })
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
        present(alert, animated: isViewAnimated)
    }
    
    private func changePasswordTimerDisplaying(){
        let vc = UserProfileSetTimerPassword()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        nav.sheetPresentationController?.detents = [.custom(resolver: { [unowned self] context in
            self.view.frame.size.height/3
        })]
        nav.sheetPresentationController?.prefersGrabberVisible = true
        nav.isNavigationBarHidden = false
        present(nav, animated: isViewAnimated)
    }
    
    
    
}
//MARK: - Safari delegate
extension UserProfileViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        dismiss(animated: isViewAnimated) {
            self.tabBarController?.tabBar.isHidden = false
        }
    }
}

//MARK: - Check Success Delegate
extension UserProfileViewController: CheckSuccessSaveProtocol, ChangeFontDelegate {
    func changeFont(font size: CGFloat, style: String) {
        restartApp()
        tableView.reloadData()
    }

    
    func isSavedCompletely(boolean: Bool) {
        tabBarController?.tabBar.isHidden = false
        if boolean {
            showAlertForUser(text: "Password was created".localized(), duration: .now()+1, controllerView: view)
            passwordBoolean = UserDefaults.standard.bool(forKey: "isPasswordCodeEnabled")
        }
    }
}

//MARK: - Table view delegate and data source
extension UserProfileViewController: UITableViewDelegate, UITableViewDataSource {
    //header and footer setups
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0...4: return cellArray[section].count
        default: return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return cellArray.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UserProfileHeaderView()
        view.setupText(indexPath: section)
        return view 
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UserProfileFooterView()
        view.setupTextLabel(section: section)
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return fontSizeValue * 3
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch section {
        case 0...3: return fontSizeValue * 4
        default: return 0
        }
    }
    
    //cell setups
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UserProfileTableViewCell.identifier,for: indexPath) as! UserProfileTableViewCell
        let data = cellArray[indexPath.section][indexPath.row]
        cell.configureCell(text: data.title, imageCell: data.cellImage, image: data.cellImageColor)
        cell.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        cell.configureSwitch(indexPath: indexPath)
        cell.switchButton.removeTarget(nil, action: nil, for: .allEvents)
        if indexPath == [2,0] {
            let appIcon = UIApplication.shared.alternateIconName ?? "AppIcon.png"
            let iconImage = UIImage(named: appIcon)?.withRenderingMode(.alwaysOriginal)
            let image = imageWith(image: iconImage!)
            cell.cellImageView.image = image
            cell.cellImageView.contentMode = .scaleAspectFit
        }
        
        switch indexPath {
        case [0,0]:
            cell.switchButton.isOn = userInterface.checkDarkModeUserDefaults() ?? false
            cell.switchButton.addTarget(self, action: #selector(didTapSwitchDisplayMode), for: .valueChanged)
        case [0,1]:
            cell.switchButton.addTarget(self, action: #selector(didTapChangeAccessNotifications), for: .touchUpInside)
            showNotificationAccessStatus { access in
                DispatchQueue.main.async {
                    cell.switchButton.isOn = access
                }
            }
        case [0,2]:
            cell.switchButton.addTarget(self, action: #selector(didTapChangeAccessCalendar), for: .touchUpInside)
            request(forAllowing: eventStore) { access in
                DispatchQueue.main.async {
                    cell.switchButton.isOn = access
                }
            }
        case [0,3]:
            cell.switchButton.addTarget(self, action: #selector(didTapChangeAccessToContacts), for: .touchUpInside)
            checkAuthForContacts { success in
                DispatchQueue.main.async {
                    cell.switchButton.isOn = success
                }
            }
        case [0,4]:
            cell.switchButton.addTarget(self, action: #selector(didTapChangeAccessToMedia), for: .touchUpInside)
            checkAccessForMedia { success in
                DispatchQueue.main.async {
                    cell.switchButton.isOn = success
                }
            }
        case [1,0]:
            cell.switchButton.addTarget(self, action: #selector(didTapChangeAccessToFaceID), for: .touchUpInside)
            let value = UserDefaults.standard.bool(forKey: "accessToFaceID")
            if !value {
                checkAuthForFaceID { success in
                    DispatchQueue.main.async {
                        cell.switchButton.isOn = success
                    }
                }
            } else {
                cell.switchButton.isOn = value
            }
        case [1,1]:
            let passwordEnabled = UserDefaults.standard.bool(forKey: "isPasswordCodeEnabled")
            if passwordEnabled {
                cell.cellImageView.image = UIImage(systemName: "lock.fill")!
            } else {
                cell.cellImageView.image = UIImage(systemName: "lock.open.fill")
            }
        case [2,2]:
            cell.switchButton.addTarget(self, action: #selector(didTapDisableAnimation), for: .valueChanged)
            cell.switchButton.isOn = UserDefaults.standard.bool(forKey: "enabledAnimation")
        case [2,3]:
            cell.switchButton.addTarget(self, action: #selector(didTapChangeNapticStyle), for: .valueChanged)
            cell.switchButton.isOn = UserDefaults.standard.bool(forKey: "enableVibration")

        default:
            break
        }
    
        cell.layer.cornerRadius = 12
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        setupHapticMotion(style: .soft)
        tableView.deselectRow(at: indexPath, animated: isViewAnimated)
        switch indexPath {
        case [1,1]:
            if passwordBoolean {
                openPasswordController(title: "Warning!".localized(), message: "Do you want to switch off or change password?".localized(), alertTitle: "Change password".localized())
            } else {
                openPasswordController()
            }
        case [1,2]:
            changePasswordTimerDisplaying()
        case [2,0]:
            openSelectionChangeIcon()
        case [2,1]:
            openChangeFontController()
        case [3,0]:
            showVariationsWithLanguage(title: "Change language".localized(), message: "") {  result in  }
        case [3,1]:
            if !InformationVisualView().isHidden {
                showInfoAuthentication(text: infoText, controller: view)
            }
        case [4,0]:
            deleteAccount()
        case [4,1]:
            changeAccountPassword()
        case [4,2]:
            didTapLogout()
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        fontSizeValue * 4
    }
    
    
}

extension UserProfileViewController: UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.editedImage] as? UIImage{
            guard let data = image.jpegData(compressionQuality: 0.5) else { return}
            let encode = try! PropertyListEncoder().encode(data)
            UserDefaults.standard.setValue(encode, forKey: "userImage")
            UserDefaults.standard.set(nil, forKey: "userImageURL")
            userImageView.image = image
        }
        picker.dismiss(animated: isViewAnimated)
        activityIndicator.stopAnimating()
        view.alpha = 1
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: isViewAnimated)
        view.alpha = 1
        
    }
}

extension UserProfileViewController  {
    private func configureConstraints(){

        let infoStack = UIStackView(arrangedSubviews: [userNameLabel, mailLabel, ageLabel])
        infoStack.alignment = .fill
        infoStack.contentMode = .scaleAspectFit
        infoStack.axis = .vertical
        infoStack.spacing = 10
        
        view.addSubview(profileView)
        profileView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(300)
        }
        
        profileView.addSubview(userImageView)
        let fixedSize = view.frame.size.width/4
        userImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            make.leading.equalToSuperview().offset(30)
            make.width.height.equalTo(fixedSize)
            self.userImageView.layer.cornerRadius = fixedSize/2
        }
        
        profileView.addSubview(changeUserImageView)
        changeUserImageView.snp.makeConstraints { make in
            make.top.equalTo(userImageView.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(30)
            make.width.equalTo(fixedSize)
            make.height.equalTo(fixedSize/3)
        }
        
        profileView.addSubview(infoStack)
        infoStack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            make.trailing.equalToSuperview().inset(-10)
            make.leading.equalTo(userImageView.snp.trailing).offset(10)
            make.height.equalTo(100)
        }
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(profileView.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
}

