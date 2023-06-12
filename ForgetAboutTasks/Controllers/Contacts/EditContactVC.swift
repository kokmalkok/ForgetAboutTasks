//
//  EditContactViewController.swift
//  ForgetAboutTasks
//
//  Created by Константин Малков on 31.05.2023.
//

import UIKit
import MessageUI
import SnapKit
import Contacts
import MapKit

class EditContactViewController: UIViewController {
    
    weak var delegate: CheckSuccessSaveProtocol?
    
    private let headerArray = ["Name","Phone and Mail","Address","Birthday","Type of contact"]
    private var cellsName = [["Enter Name", "Enter Second Name"],
                             ["Enter Phone number","Enter Mail"],
                             ["Country","City","Address","Postal Code"],
                             ["Choose date"],
                             ["Choose Type of contact"]]
    
    private var contactModel: ContactModel
    private var editedContactModel = ContactModel()
    private var isViewEdited: Bool
    
    init(contactModel: ContactModel,editing: Bool){
        self.contactModel = contactModel
        self.isViewEdited = editing
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - UI elements
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let viewForTable = NewContactCustomView()
    
    private lazy var shareModelButton: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up.fill"), style: .done, target: self, action: #selector(didTapShareTable))
    }()
    
    private lazy var editModelButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(didTapEdit))
    }()
    
    private let labelForImageView: UILabel = {
        let label = UILabel()
        label.text = "Choose image"
        label.textColor = .systemGray
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupView()
    }
    
    //MARK: - Targets methods
    @objc private func didTapSave(){
        let id = contactModel.contactID
        ContactRealmManager.shared.editAllTasksModel(user: id, newModel: editedContactModel)
        delegate?.isSavedCompletely(boolean: true)
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func didTapOpenPhoto(){
        alertImagePicker { [weak self] sourceType in
            self?.chooseImagePicker(source: sourceType)
        }
    }
    
    @objc private func didTapEdit(){
        isViewEdited = !isViewEdited
        setupSelection(boolean: isViewEdited)
        customiseView()
    }
    //НЕ РАБОТАЕТ. НЕ ОТОБРАЖАЕТ КОНТРОЛЛЕР
    @objc private func didTapShareTable(){
        let shareContact = CNMutableContact()
        let model = contactModel

        let phoneValue = CNPhoneNumber(stringValue: model.contactPhoneNumber ?? "No phone number")
        shareContact.givenName = model.contactName ?? "Name is unavaliable"
        shareContact.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMain, value: phoneValue)]
        shareContact.imageData = model.contactImage ?? Data()
        
        let contact = try! CNContactVCardSerialization.data(with: [shareContact])
        let activityVC = UIActivityViewController(activityItems: [contact], applicationActivities: nil)
        self.present(activityVC, animated: true)
    }
    //MARK: - Setup methods
    private func setupView() {
        setupNavigationController()
        setupConstraints()
        customiseView()
        setupSelection(boolean: isViewEdited)
        view.backgroundColor = UIColor(named: "backgroundColor")
        title = "Edit Contact"
    }
    
    private func setupTableView(){
        tableView.isScrollEnabled = true
        tableView.bounces = true
        tableView.backgroundColor = UIColor(named: "backgroundColor")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "tasksCell")
    }
    
    private func setupSelection(boolean: Bool){
        if !boolean {
            editModelButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(didTapEdit))
        } else {
            editModelButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(didTapSave))
            navigationItem.setRightBarButton(editModelButton, animated: true)
            shareModelButton.isHidden = true
            
        }
    }
    
    private func setupNavigationController(){
        navigationItem.rightBarButtonItems = [editModelButton, shareModelButton]
        navigationController?.navigationBar.tintColor = UIColor(named: "navigationControllerColor")
        navigationController?.navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    private func customiseView(){
        viewForTable.backgroundColor = .clear
        viewForTable.viewForImage.backgroundColor = .clear
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapOpenPhoto))
        gesture.numberOfTapsRequired = 1
        if isViewEdited {
            viewForTable.addGestureRecognizer(gesture)
            labelForImageView.isHidden = false
        }
    }
    
    private func setupComposeView(model: ContactModel){
        if MFMailComposeViewController.canSendMail() {
            let vc = MFMailComposeViewController()
            vc.mailComposeDelegate = self
            guard let name = model.contactName,
                  let mail = model.contactMail else { return }
            
            vc.setToRecipients([mail])
            vc.setSubject("Hello, \(name)")
            vc.setMessageBody("Some text for sending", isHTML: false)
            
            show(vc, sender: nil)
        } else {
            alertError(text: "You can't send email. Maybe you don't Have Apple Mail App on your device?")
        }
    }
    
    private func setupPhoneCalling(){
        guard let phone = contactModel.contactPhoneNumber?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "tel://\(phone)") else {
                self.alertError(text: "Incorrect number")
                return
        }
        if UIApplication.shared.canOpenURL(url){
            UIApplication.shared.open(url)
        } else {
            self.alertError(text: "This function is not avaliable.\nTry again later", mainTitle: "Error!")
        }
    }
    
    
    private func setupOpenCalendar(){
        guard let date = contactModel.contactDateBirthday else { alertError(text: "Cant get date", mainTitle: "Error"); return}
        let vc = CreateTaskForDayController(choosenDate: date)
        show(vc, sender: nil)
    }
    
    private func setupOpenAddressInMap(){
        guard let country = contactModel.contactCountry,
              let city = contactModel.contactCity,
              let address = contactModel.contactAddress else {
            alertError(text: "Value is empty. Can't open location", mainTitle: "Error")
            return
        }
        let addressValue = country + " " + city + " " + address
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(addressValue) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else { return }
            let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
            mapItem.name = addressValue
            mapItem.openInMaps()
        }
    }
}
    //MARK: - Segue methods
extension EditContactViewController: MFMailComposeViewControllerDelegate{
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
    //MARK: - Table view delegates and data sources
extension EditContactViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2
        case 1: return 2
        case 2: return 4
        case 3: return 1
        case 4: return 1
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tasksCell", for: indexPath)
        cell.backgroundColor = UIColor(named: "cellColor")
        let basicValue = cellsName[indexPath.section][indexPath.row]
        
        let segueButton = UIButton()
        segueButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        segueButton.sizeToFit()
        segueButton.tag = indexPath.row
        
        
        if let image = contactModel.contactImage {
            viewForTable.contactImageView.image = UIImage(data: image)
            viewForTable.contactImageView.layer.cornerRadius = viewForTable.contactImageView.frame.size.width/2
            viewForTable.contactImageView.contentMode = .scaleAspectFit
            viewForTable.contactImageView.clipsToBounds = true
            labelForImageView.isHidden = true
        }
        if !isViewEdited {
            switch indexPath {
            case [0,0]:
                cell.textLabel?.text = contactModel.contactName
            case [0,1]:
                cell.textLabel?.text = contactModel.contactSurname
            case [1,0]:
                let phoneNumber = String.format(with: "+X (XXX) XXX-XXXX", phone: contactModel.contactPhoneNumber ?? "")
                cell.textLabel?.text = phoneNumber
                segueButton.setImage(UIImage(systemName: "phone.fill"), for: .normal)
                segueButton.tintColor = UIColor(named: "navigationControllerColor")
                cell.accessoryView = segueButton
            case [1,1]:
                cell.textLabel?.text = contactModel.contactMail
                segueButton.setImage(UIImage(systemName: "envelope.fill"), for: .normal)
                segueButton.tintColor = UIColor(named: "navigationControllerColor")
                cell.accessoryView = segueButton
            case [2,0]:
                cell.textLabel?.text = "Contry: " +  (contactModel.contactCountry ?? basicValue)
                segueButton.setImage(UIImage(systemName: "mappin.circle.fill"), for: .normal)
                segueButton.tintColor = UIColor(named: "navigationControllerColor")
                cell.accessoryView = segueButton
            case [2,1]:
                cell.textLabel?.text = "City: " + (contactModel.contactCity ?? basicValue)
            case [2,2]:
                cell.textLabel?.text = "Street: " + (contactModel.contactAddress ?? basicValue)
            case [2,3]:
                cell.textLabel?.text = "Postal code: " + (contactModel.contactPostalCode ?? basicValue)
            case [3,0]:
                if let birthday = contactModel.contactDateBirthday {
                    cell.textLabel?.text = DateFormatter.localizedString(from: birthday, dateStyle: .medium, timeStyle: .none)
                } else {
                    cell.textLabel?.text = ""
                }
                segueButton.setImage(UIImage(systemName: "calendar"), for: .normal)
                segueButton.tintColor = UIColor(named: "navigationControllerColor")
                cell.accessoryView = segueButton
            case [4,0]:
                cell.textLabel?.text = contactModel.contactType ?? "Not indicated"
            default:
                print("Error")
            }
        } else {
            cell.accessoryView = nil
            switch indexPath {
            case [0,0]:
                cell.textLabel?.text = editedContactModel.contactName ?? contactModel.contactName
            case [0,1]:
                cell.textLabel?.text = editedContactModel.contactSurname ?? contactModel.contactSurname
            case [1,0]:
                let phoneNumber = String.format(with: "+X (XXX) XXX-XX-XX", phone: (editedContactModel.contactPhoneNumber ?? contactModel.contactPhoneNumber) ?? "No value number")
                cell.textLabel?.text = phoneNumber
            case [1,1]:
                cell.textLabel?.text = editedContactModel.contactMail ?? contactModel.contactMail
            case [2,0]:
                cell.textLabel?.text = editedContactModel.contactCountry ?? contactModel.contactCountry
            case [2,1]:
                cell.textLabel?.text = editedContactModel.contactCity ?? contactModel.contactCity
            case [2,2]:
                cell.textLabel?.text = editedContactModel.contactAddress ?? contactModel.contactAddress
            case [2,3]:
                cell.textLabel?.text = editedContactModel.contactPostalCode
            case [3,0]:
                cell.textLabel?.text = DateFormatter.localizedString(from: (editedContactModel.contactDateBirthday ?? contactModel.contactDateBirthday) ?? Date(), dateStyle: .medium, timeStyle: .none)
            case [4,0]:
                cell.textLabel?.text = editedContactModel.contactType ?? contactModel.contactType ?? "Not indicated"
            default:
                print("Error")
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cellName = cellsName[indexPath.section][indexPath.row]
        let cell = tableView.cellForRow(at: indexPath)
        if isViewEdited {
            switch indexPath{
            case [0,0]:
                alertTextField(cell: cellName, placeholder: "Enter first name", keyboard: .default) { [unowned self] text in
                    self.cellsName[indexPath.section][indexPath.row] = text
                    cell?.textLabel?.text = text
                    editedContactModel.contactName = text
                }
            case [0,1]:
                alertTextField(cell: cellName, placeholder: "Enter second name", keyboard: .default) { [unowned self] text in
                    self.cellsName[indexPath.section][indexPath.row] = text
                    cell?.textLabel?.text = text
                    editedContactModel.contactSurname = text
                }
            case [1,0]:
                alertPhoneNumber(cell: cellName, placeholder: "Enter valid number", keyboard: .numberPad) { [unowned self] text in
                    self.cellsName[indexPath.section][indexPath.row] = text
                    cell?.textLabel?.text = text
                    editedContactModel.contactPhoneNumber = text
                }
            case [1,1]:
                alertTextField(cell: cellName, placeholder: "Enter mail", keyboard: .emailAddress) { [weak self] text in
                    if text.emailValidation(email: text) {
                        self?.cellsName[indexPath.section][indexPath.row] = text.lowercased()
                        self?.editedContactModel.contactMail = text
                        cell?.textLabel?.text = text
                    } else {
                        self?.alertError(text: "Enter the @ domain and country domain", mainTitle: "Warning")
                    }
                }
            case [2,0]: alertTextField(cell: cellName, placeholder: "Enter name of country", keyboard: .default) { [weak self]  text in
                cell?.textLabel?.text = text
                self?.editedContactModel.contactCountry = text
            }
            case [2,1]: alertTextField(cell: cellName, placeholder: "Enter name of city", keyboard: .default) { [weak self]  text in
                cell?.textLabel?.text = text
                self?.editedContactModel.contactCity = text
            }
            case [2,2]: alertTextField(cell: cellName, placeholder: "Enter the address", keyboard: .default) { [weak self]  text in
                cell?.textLabel?.text = text
                self?.editedContactModel.contactAddress = text
            }
            case [2,3]: alertTextField(cell: cellName, placeholder: "Enter postal code", keyboard: .default) { [weak self]  text in
                cell?.textLabel?.text = text
                self?.editedContactModel.contactPostalCode = text
            }
            case [3,0]: alertDate( choosenDate: Date()) { [weak self] _, birthday, text in
                cell?.textLabel?.text = text
                self?.editedContactModel.contactDateBirthday = birthday
            }
            case [4,0]:
                alertFriends { [ weak self] text in
                    self?.cellsName[indexPath.section][indexPath.row] = text
                    self?.editedContactModel.contactType = text
                    cell?.textLabel?.text = text
                }
            default:
                print("error")
            }
        } else {
            switch indexPath {
            case [1,0]:
                setupPhoneCalling()
            case [1,1]:
                setupComposeView(model: contactModel)
            case [2,indexPath.row]:
                setupOpenAddressInMap()
            case [3,0]:
                setupOpenCalendar()
            default:
                print("Error")
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return headerArray[section]
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
}

extension EditContactViewController: UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    func chooseImagePicker(source: UIImagePickerController.SourceType) {
        if UIImagePickerController.isSourceTypeAvailable(source){
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            imagePicker.sourceType = source
            present(imagePicker, animated: true)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.editedImage] as? UIImage
        viewForTable.contactImageView.image = image
        viewForTable.contactImageView.contentMode = .scaleAspectFill
        viewForTable.contactImageView.clipsToBounds = true
        viewForTable.contactImageView.layer.cornerRadius = viewForTable.contactImageView.frame.size.width/2
        let finalEditImage = viewForTable.contactImageView.image
        guard let data = finalEditImage?.pngData() else { return }
        editedContactModel.contactImage = data
        dismiss(animated: true)
    }
}



extension EditContactViewController {
    private func setupConstraints(){
        
        view.addSubview(viewForTable)
        viewForTable.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
            make.height.width.equalTo(180)
            make.centerX.equalToSuperview()
        }
        
        view.addSubview(labelForImageView)
        labelForImageView.snp.makeConstraints { make in
            make.top.equalTo(viewForTable.snp.bottom).offset(10)
            make.height.equalTo(25)
            make.centerX.equalToSuperview()
        }
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(labelForImageView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(10)
            make.bottom.equalToSuperview().offset(10)
        }
        
    }
}
