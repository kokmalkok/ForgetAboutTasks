//
//  EditEventScheduleVC.swift
//  ForgetAboutTasks
//
//  Created by Константин Малков on 20.05.2023.
//

import UIKit
import RealmSwift
import SnapKit
import Combine
import EventKit

class EditEventScheduleViewController: UIViewController {
    
    weak var delegate: CheckSuccessSaveProtocol?
    
    private let headerArray = ["Details of event".localized()
                               ,"Start and End of event".localized()
                               ,"Category of event".localized()
                               ,"Color of event".localized()
                               ,"Choose image".localized()]
    
    private var cellsName = [[""],
                     ["","","Set a reminder".localized(),"Add to Calendar".localized()],
                     ["","","",""],
                     [""],
                     [""]]
    
    private var cellBackgroundColor: UIColor
    private var choosenDate: Date
    private var scheduleModel: ScheduleModel
    private var editedScheduleModel = ScheduleModel()
    private let userNotificationCenter = UNUserNotificationCenter.current()
    private let eventStore = EKEventStore()
    private var reminderStatus: Bool = false
    private var isStartEditing: Bool = false
    private var addingToEvent: Bool = false
    private var cancellable: AnyCancellable?//for parallels displaying color in cell and Combine Kit for it
    private lazy var changableChoosenDate = choosenDate
    
    init(cellBackgroundColor: UIColor, choosenDate: Date, scheduleModel: ScheduleModel){
        self.cellBackgroundColor = cellBackgroundColor
        self.choosenDate = choosenDate
        self.scheduleModel = scheduleModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - UI Elemets
    private lazy var navigationItemButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(didTapEdit))
    }()
    private let picker = UIColorPickerViewController()
    private let tableView = UITableView(frame: CGRectZero, style: .insetGrouped)
    private var imagePicker = UIImagePickerController()
    
    private let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.configuration = .bordered()
        button.configuration?.title = "Delete event"
        button.configuration?.image = UIImage(systemName: "trash")
        button.configuration?.imagePlacement = .leading
        button.configuration?.imagePadding = 3
        button.configuration?.baseBackgroundColor = .systemRed
        button.configuration?.baseForegroundColor = .systemRed
        return button
    }()
    //MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    //MARK: - Targets methods
    @objc private func didTapDismiss(){
        setupHapticMotion(style: .medium)
        if isStartEditing {
            setupAlertSheet(title: "Attention".localized()
                            ,subtitle: "You have some changes.\nWhat do you want to do".localized())
        } else {
            dismiss(animated: isViewAnimated)
        }
    }
    
    @objc private func didTapEdit(){
        setupHapticMotion(style: .soft)
        let color = cellBackgroundColor.encode()
        editedScheduleModel.scheduleColor = color
        let id = scheduleModel.scheduleModelId
        if isStartEditing {
            ScheduleRealmManager.shared.editScheduleModel(user: id, changes: editedScheduleModel)
            DispatchQueue.main.async {
                self.addNewUserNotification(model: self.editedScheduleModel, status: self.reminderStatus)
                self.createNewEvent(model: self.editedScheduleModel, status: self.addingToEvent)
                self.delegate?.isSavedCompletely(boolean: true)
                self.dismiss(animated: isViewAnimated)
            }
        }
    }
    
    @objc private func didTapSetReminder(sender: UISwitch){
        if sender.isOn {
            if dataFieldCheck() {
                alertError(text: "Enter date for setting reminder".localized()
                           ,mainTitle: "Error set up reminder!".localized())
                sender.isOn = false
            } else {
                request(forUser: userNotificationCenter) { access in
                    self.reminderStatus = access
                    self.isStartEditing = access
                    self.editedScheduleModel.scheduleActiveNotification = access
                }
            }
        } else {
            reminderStatus = false
            editedScheduleModel.scheduleActiveNotification = false
        }
    }
    
    @objc private func didTapAddEvent(switchButton: UISwitch){
        if switchButton.isOn {
            if  dataFieldCheck() && editedScheduleModel.scheduleName == "" {
                alertError(text: "Check Name,Start Date and End Date.\nThey must have some property".localized()
                           , mainTitle: "Error!".localized())
            } else {
                request(forAllowing: eventStore) { access in
                    self.addingToEvent = access
                    self.isStartEditing = access
                    self.editedScheduleModel.scheduleActiveCalendar = access
                }
            }
        } else {
            addingToEvent = false
            editedScheduleModel.scheduleActiveCalendar = false
        }
        
    }

    
    //MARK: - Setup Views and secondary methods
    private func setupView() {
        setupConstraints()
        setupNavigationController()
        setupDelegate()
        setupColorPicker()
        setupTableView()
        view.backgroundColor = UIColor(named: "backgroundColor")
        title = "Editing event".localized()
    }
    
    private func dataFieldCheck() -> Bool {
        if (editedScheduleModel.scheduleStartDate == nil || scheduleModel.scheduleStartDate == nil) && (editedScheduleModel.scheduleTime == nil || scheduleModel.scheduleEndDate == nil) {
            return false
        } else {
            return true
        }
    }
    
    private func setupDelegate(){
        picker.delegate = self
    }
    
    private func setupTableView(){
        tableView.backgroundColor = UIColor(named: "backgroundColor")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.register(ScheduleTableViewCell.self, forCellReuseIdentifier: ScheduleTableViewCell.identifier)
    }
    
    private func setupColorPicker(){
        picker.selectedColor = self.view.backgroundColor ?? #colorLiteral(red: 0.3555810452, green: 0.3831118643, blue: 0.5100654364, alpha: 1)
    }
    
    private func setupNavigationController(){
        navigationController?.navigationBar.tintColor = UIColor(named: "calendarHeaderColor")
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didTapDismiss))
        deleteButton.tintColor = .systemRed
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = navigationItemButton
        if isStartEditing {
            navigationItemButton.isEnabled = false
        } else {
            navigationItemButton.isEnabled = true
        }

    }
    //MARK: - Business logics methods
    
    
    /// Function for creating users notification if it necessary
    /// - Parameters:
    ///   - model: input data from realm model
    ///   - status: boolean value check if app has access to UserNotifications
    private func addNewUserNotification(model: ScheduleModel, status: Bool){
        if status {
            let center = UNUserNotificationCenter.current()
            let content = UNMutableNotificationContent()
            let dateS = model.scheduleTime ?? Date()
            let date = DateFormatter.localizedString(from: dateS, dateStyle: .medium, timeStyle: .none)
            let body = String(describing: model.scheduleName ?? "")
            content.title = "Planned reminder".localized()
            content.body = body
            content.subtitle = date
            content.sound = .default
            let dateFormat = DateFormatter.localizedString(from: scheduleModel.scheduleStartDate ?? Date(), dateStyle: .medium, timeStyle:.none)
            content.userInfo = ["userNotification": dateFormat]
            let components = Calendar.current.dateComponents([.day,.month,.year,.hour,.minute,.second], from: dateS)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: "request", content: content, trigger: trigger)
            center.add(request) { [weak self] error in
                if error != nil {
                    self?.alertError()
                } else {
                    self?.editedScheduleModel.scheduleActiveNotification = status
                }
            }
        } else {
            editedScheduleModel.scheduleActiveNotification = status
        }
    }
    
    
    /// Function check access to EKEvent
    /// - Parameters:
    ///   - model: input data from realm model
    ///   - status: boolean value check if app has access to EKEvent
    private func createNewEvent(model:ScheduleModel,status: Bool){
        let eventStore: EKEventStore = EKEventStore()
        switch EKEventStore.authorizationStatus(for: .event){
            
        case .notDetermined:
            eventStore.requestAccess(to: .event) { success, error in
                if success {
                    self.setupAddingEventToCalendar(store: eventStore, model: model, status: status)
                } else {
                    self.alertError(text: "Cant save event in Calendar".localized(), mainTitle: "Warning!".localized())
                }
            }
        case .restricted:
            break
        case .denied:
            alertError(text: "Cant save event in Calendar".localized(), mainTitle: "Warning!".localized())
        case .authorized:
            setupAddingEventToCalendar(store: eventStore, model: model, status: status)
        @unknown default:
            break
        }
    }
    
    /// Function for adding event to system Calendar app
    /// - Parameters:
    ///   - store: input current EKEventStore
    ///   - model: input current data model
    ///   - status: boolean value if user give access to EKEvent
    private func setupAddingEventToCalendar(store: EKEventStore,model: ScheduleModel, status: Bool){
        if let calendar = store.defaultCalendarForNewEvents{
            if status {
                let event: EKEvent = EKEvent(eventStore: store)
                event.calendar = calendar
                event.startDate = model.scheduleStartDate
                event.endDate = model.scheduleEndDate
                event.title = model.scheduleName
                event.url = URL(string: model.scheduleCategoryURL ?? "")
                event.notes = model.scheduleCategoryNote
                let reminder = EKAlarm(absoluteDate: model.scheduleStartDate ?? Date())
                event.alarms = [reminder]
                do {
                    try store.save(event, span: .thisEvent)
                    editedScheduleModel.scheduleActiveCalendar = true
                } catch let error as NSError{
                    alertError(text: error.localizedDescription)
                }
            }
        } else {
            alertError(text: "Error saving event to calendar".localized())
            editedScheduleModel.scheduleActiveCalendar = false
        }
    }
    
    private func setupCellTitle(model: ScheduleModel,indexPath: IndexPath){
        let dateTime = model.scheduleTime ?? Date()
        let endDateTime = model.scheduleStartDate ?? Date()
        switch indexPath {
        case [0,0]: cellsName[indexPath.section][indexPath.row] = model.scheduleName ?? ""
        case [1,0]: cellsName[indexPath.section][indexPath.row] = DateFormatter.localizedString(from: dateTime, dateStyle: .medium, timeStyle: .short)
        case [1,1]: cellsName[indexPath.section][indexPath.row] = DateFormatter.localizedString(from: endDateTime, dateStyle: .medium, timeStyle: .short)
        case [2,0]: cellsName[indexPath.section][indexPath.row] = model.scheduleCategoryName ?? "Set Name of event".localized()
        case [2,1]: cellsName[indexPath.section][indexPath.row] = model.scheduleCategoryType ?? "Set Type of event".localized()
        case [2,2]: cellsName[indexPath.section][indexPath.row] = model.scheduleCategoryURL ?? "Set URL".localized()
        case [2,3]: cellsName[indexPath.section][indexPath.row] = model.scheduleCategoryNote ?? "Enter some notes".localized()
        default:
            break
        }
    }
    
    private func setupAlertIfDataEmpty() -> Bool{
        setupHapticMotion(style: .medium)
        if scheduleModel.scheduleName == "Unknown" {
            alertError(text: "Enter value in Name cell".localized())
            return false
        } else if scheduleModel.scheduleStartDate == nil {
            alertError(text: "Specify start of event".localized())
            return false
        } else if scheduleModel.scheduleTime == nil {
            alertError(text: "Specify end of event".localized())
            return false
        } else {
            return true
        }
    }

    //MARK: - Segue methods
    ///Method with dispatch of displaying color in cell while choosing color in picker view
    @objc private func openColorPicker(){
        setupHapticMotion(style: .soft)
        self.cancellable = picker.publisher(for: \.selectedColor) .sink(receiveValue: { color in
            DispatchQueue.main.async {
                self.cellBackgroundColor = color
                self.isStartEditing = true
            }
        })
        self.present(picker, animated: isViewAnimated)
    }
    ///Alert controller for choosing type of image
    @objc private func chooseTypeOfImagePicker() {
        setupHapticMotion(style: .soft)
        let alert = UIAlertController(title: "", message: "What exactly do you want to do?".localized(), preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Set new image".localized(), style: .default,handler: { [self] _ in
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
                imagePicker.delegate = self
                imagePicker.sourceType = .photoLibrary
                imagePicker.allowsEditing = true
                present(self.imagePicker, animated: isViewAnimated)
                isStartEditing = true
            }
        }))
        alert.addAction(UIAlertAction(title: "Make new image".localized(), style: .default,handler: { [self] _ in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                imagePicker.delegate = self
                imagePicker.sourceType = .camera
                imagePicker.allowsEditing = true
                present(self.imagePicker, animated: isViewAnimated)
                isStartEditing = true
            }
        }))
        alert.addAction(UIAlertAction(title: "Delete image".localized(), style: .destructive,handler: { _ in
            let cell = self.tableView.cellForRow(at: [4,0])
            cell?.imageView?.image = UIImage(named: "camera.fill")
            self.isStartEditing = true
        }))
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
        present(alert, animated: isViewAnimated)
    }
    //MARK: - Image Picker Delegate
    
}
extension EditEventScheduleViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.editedImage] as? UIImage{
            guard let data = image.jpegData(compressionQuality: 1.0) else { return}

            editedScheduleModel.scheduleImage = data
            tableView.reloadData()
            picker.dismiss(animated: isViewAnimated)
            tableView.deselectRow(at: [4,0], animated: isViewAnimated)
        } else {
            alertError(text: "Error!".localized(), mainTitle: "Can't get image and save it to event.\nTry again later!".localized())
        }
        
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        tableView.deselectRow(at: [4,0], animated: isViewAnimated)
        picker.dismiss(animated: isViewAnimated)
    }
}

//MARK: - Table view delegates
extension EditEventScheduleViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 4
        case 2: return 4
        case 3: return 1
        default: return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        let customCell = tableView.dequeueReusableCell(withIdentifier: ScheduleTableViewCell.identifier) as? ScheduleTableViewCell
        if !isStartEditing {
            setupCellTitle(model: scheduleModel, indexPath: indexPath)
        }
        let data = cellsName[indexPath.section][indexPath.row]
        
        cell?.textLabel?.numberOfLines = 0
        cell?.textLabel?.font = .setMainLabelFont()
        cell?.contentView.layer.cornerRadius = 10
        cell?.backgroundColor = UIColor(named: "cellColor")
        
        let switchButton = UISwitch(frame: .zero)
        switchButton.isOn = false
        switchButton.isHidden = true
        switchButton.onTintColor = cellBackgroundColor
        cell?.accessoryView = switchButton
        
        cell?.textLabel?.text = data
        if indexPath == [3,0] {
            cell?.backgroundColor = cellBackgroundColor
        } else if indexPath == [1,2] {
            cell?.accessoryView?.isHidden = false
            switchButton.addTarget(self, action: #selector(didTapSetReminder), for: .touchUpInside)
            switchButton.isOn = scheduleModel.scheduleActiveNotification ?? false
        } else if indexPath == [1,3] {
            cell?.accessoryView?.isHidden = false
            switchButton.addTarget(self, action: #selector(didTapAddEvent), for: .touchUpInside)
            switchButton.isOn = scheduleModel.scheduleActiveCalendar ?? false
        } else if indexPath == [4,0] {
            let data = editedScheduleModel.scheduleImage ?? scheduleModel.scheduleImage ?? Data()
            customCell?.imageViewSchedule.image = UIImage(data: data)
            return customCell!
        } else {
            cell?.accessoryView = nil
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: isViewAnimated)
        let cellName = cellsName[indexPath.section][indexPath.row]
        let cell = tableView.cellForRow(at: indexPath)
        
            switch indexPath {
            case [0,0]:
                alertTextField(cell: cellName, placeholder: "Enter the text".localized(), keyboard: .default) {[self] text in
                    editedScheduleModel.scheduleName = text
                    cell?.textLabel?.text = text
                    isStartEditing = true
                }
            case [1,0]:
                alertTimeInline(choosenDate: choosenDate) { [self] date, timeString, weekday in
                    editedScheduleModel.scheduleTime = date
                    editedScheduleModel.scheduleStartDate = date
                    editedScheduleModel.scheduleWeekday = weekday
                    changableChoosenDate = date.addingTimeInterval(3600)
                    cell?.textLabel?.text = timeString
                    isStartEditing = true
                }
            case [1,1]:
                alertTimeInline(choosenDate: changableChoosenDate) { [self] date, timeString, _ in
                    editedScheduleModel.scheduleEndDate = date
                    cell?.textLabel?.text = timeString
                    isStartEditing = true
                }
            case [2,0]:
                alertTextField(cell: "Enter Name of event".localized(), placeholder: "Enter the text".localized(), keyboard: .default) { [self] text in
                    editedScheduleModel.scheduleCategoryName = text
                    cell?.textLabel?.text = text
                    isStartEditing = true
                }
            case [2,1]:
                alertTextField(cell: "Enter Type of event".localized(), placeholder: "Enter the text".localized(), keyboard: .default) { [self] text in
                    editedScheduleModel.scheduleCategoryType = text
                    cell?.textLabel?.text = text
                    isStartEditing = true
                }
            case [2,2]:
                alertTextField(cell: "Enter URL name with domain".localized(), placeholder: "Enter URL".localized(), keyboard: .URL) { [self] text in
                    if text.urlValidation(text: text) {
                        editedScheduleModel.scheduleCategoryURL = text
                        cell?.textLabel?.text = text
                        isStartEditing = true
                    } else if !text.contains("www.") || !text.contains("http://") && text.contains("."){
                        let editedText = "www." + text
                        editedScheduleModel.scheduleCategoryURL = editedText
                        cell?.textLabel?.text = editedText
                        isStartEditing = true
                    } else {
                        alertError(text: "Enter name of URL link with correct domain".localized(), mainTitle: "Incorrect input".localized())
                    }
                }
            case [2,3]:
                alertTextField(cell: "Enter Notes of event".localized(), placeholder: "Enter the text".localized(), keyboard: .default) { [self] text in
                    editedScheduleModel.scheduleCategoryNote = text
                    cell?.textLabel?.text = text
                    isStartEditing = true
                }
            case [3,0]:
                openColorPicker()
            case [4,0]:
                tableView.selectRow(at: indexPath, animated: isViewAnimated, scrollPosition: .none)
                chooseTypeOfImagePicker()
            default:
                break
            
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return headerArray[section]
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath == [2,3] && indexPath == [4,0]{
            return UITableView.automaticDimension
        } else if indexPath == [4,0] {
            return 300
        }
        return 45
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        5
    }
    
}
//MARK: - Color picker delegate
extension EditEventScheduleViewController: UIColorPickerViewControllerDelegate {
    
    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        cellBackgroundColor = color
        let cell = tableView.cellForRow(at: [3,0])
        cell?.backgroundColor = color
    }
}

extension EditEventScheduleViewController {
    private func setupAlertSheet(title: String,subtitle: String) {
        let sheet = UIAlertController(title: title, message: subtitle, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Discard changes".localized(), style: .destructive,handler: { _ in
            self.dismiss(animated: isViewAnimated)
        }))
        sheet.addAction(UIAlertAction(title: "Save".localized(), style: .default,handler: { [self] _ in
            didTapEdit()
        }))
        sheet.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
        present(sheet, animated: isViewAnimated)
    }
    
    private func setupConstraints(){
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

