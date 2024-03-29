//
//  UserProfileAppIconViewVC.swift
//  ForgetAboutTasks
//
//  Created by Константин Малков on 03.07.2023.
//

import UIKit
import SnapKit

class UserProfileAppIconViewController: UIViewController {
    
    var checkSelectedIcon: ((Bool)->Void)?
    
    private let images = ["AppIcon", "AppIcon2","AppIcon3","AppIcon4"]
    
    private let firstIconButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.tag = 0
        button.setImage(UIImage(named: "AppIcon"), for: .normal)
        
        return button
    }()

    private let secondIconButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.tag = 1
        button.setImage(UIImage(named: "AppIcon2"), for: .normal)
        return button
    }()
    
    private let thirdIconButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.tag = 2
        button.setImage(UIImage(named: "AppIcon3"), for: .normal)
        return button
    }()
    
    private let forthIconButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.tag = 3
        button.setImage(UIImage(named: "AppIcon4"), for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewAndNavigation()
        
    }
    //MARK: - Target methods
    @objc private func didTapDismiss(){
        setupHapticMotion(style: .soft)
        dismiss(animated: isViewAnimated)
    }
    
    @objc private func didTapChangeImage(sender: UIButton){
        switch sender.tag {
        case 0: setupAppIcon(named: images[sender.tag])
        case 1: setupAppIcon(named: images[sender.tag])
        case 2: setupAppIcon(named: images[sender.tag])
        case 3: setupAppIcon(named: images[sender.tag])
        default:
            break
        }
    }
    
    
    //MARK: - Setup Method
    private func setupViewAndNavigation(){
        setConstraints()
        extractedFunc()
        setupTargets()
    }
    
    private func extractedFunc() {
        navigationController?.navigationBar.tintColor = UIColor(named: "calendarHeaderColor")
        view.backgroundColor = UIColor(named: "backgroundColor")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.down"), style: .done, target: self, action: #selector(didTapDismiss))
        title = "Choose App Icon".localized()
    }
    
    private func setupTargets() {
        let buttons = [firstIconButton, secondIconButton, thirdIconButton, forthIconButton]
        buttons.forEach { button in
                button.addTarget(self, action: #selector(didTapChangeImage(sender: )), for: .touchUpInside)
        }
        
    }
    
    /// Function for setting up chosen icon to app icon image
    /// - Parameter iconName: input assets name of image
    private func setupAppIcon(named iconName: String?) {
        guard UIApplication.shared.supportsAlternateIcons else { alertError(text: "Cant get access to change Image".localized()); return }
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error = error {
                self.alertError(text: error.localizedDescription)
            } else {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.5) {
                    self.checkSelectedIcon?(true)
                    self.dismiss(animated: isViewAnimated)
                }
            }
        }
    }
}

extension UserProfileAppIconViewController {
    private func setConstraints(){

        let stackView = UIStackView(arrangedSubviews: [firstIconButton,secondIconButton,thirdIconButton,forthIconButton])
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.contentMode = .scaleAspectFit
        stackView.axis = .horizontal
        stackView.spacing = 10
        
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(60)
            make.leading.trailing.equalToSuperview().inset(10)
            make.height.equalTo(80)
        }
    }
}
