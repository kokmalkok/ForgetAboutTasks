//
//  TaskDetailVC.swift
//  ForgetAboutTasks
//
//  Created by Константин Малков on 30.04.2023.
//

import UIKit
import SnapKit
import SafariServices

class OpenTaskDetailViewController: UIViewController {
    
    private let headerArray = ["Details of event","Date and time","Category of event","Color of event","Repeat"]
    private var cellsName = [["Name of event"],
                     ["Date", "Time"],
                     ["Name","Type","URL","Note"],
                     [""],
                     ["Repeat every 7 days"]]
    
    private var cellBackgroundColor =  #colorLiteral(red: 0.3555810452, green: 0.3831118643, blue: 0.5100654364, alpha: 1)
    private var selectedScheduleModel: ScheduleModel
    
    init(model: ScheduleModel) {
        self.selectedScheduleModel = model
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: - UI Setups view
    private lazy var shareModelButton: UIBarButtonItem = {
        return UIBarButtonItem(systemItem: .action,menu: topMenu)
    }()
    
    private lazy var startEditButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(didTapEdit))
    }()
    
    private var topMenu = UIMenu()
    private let indicator =  UIActivityIndicatorView(style: .medium)
    
    private let tableView = UITableView(frame: CGRectZero, style: .insetGrouped)
    
    
    //MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupView()
    }

    //MARK: - Targets methods
    @objc private func didTapDismiss(){
        dismiss(animated: true)
    }
    
    @objc private func didTapEdit(){
        
        let colorCell = UIColor.color(withData: selectedScheduleModel.scheduleColor!) ?? #colorLiteral(red: 0.3555810452, green: 0.3831118643, blue: 0.5100654364, alpha: 1)
        let choosenDate = selectedScheduleModel.scheduleDate ?? Date()
        let vc = EditEventScheduleViewController(cellBackgroundColor: colorCell, choosenDate: choosenDate, scheduleModel: selectedScheduleModel)
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        nav.modalTransitionStyle = .crossDissolve
        nav.isNavigationBarHidden = false
        present(nav, animated: true)
    }
    
    //MARK: - Setup Views and secondary methods
    private func setupView() {
        setupMenu()
        setupNavigationController()
        setupConstraints()
        setupGestureForDismiss()
        indicator.hidesWhenStopped = true
        view.backgroundColor = UIColor(named: "backgroundColor")
    }
    
    private func setupGestureForDismiss(){
        let gesture = UISwipeGestureRecognizer(target: self, action: #selector(didTapDismiss))
        gesture.direction = .right
        view.addGestureRecognizer(gesture)
    }
    
    private func setupTableView(){
        view.addSubview(tableView)
        tableView.backgroundColor = UIColor(named: "backgroundColor")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    private func setupNavigationController(){
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didTapDismiss))
        navigationItem.rightBarButtonItems = [startEditButton,shareModelButton]
        navigationController?.navigationBar.tintColor = UIColor(named: "navigationControllerColor")
        title = "Details"
    }
    
    private func setupMenu(){
        let shareImage = UIAction(title: "Share Image", image: UIImage(systemName: "photo.circle.fill")) { _ in
            self.shareTableView("image")
        }
        let sharePDF = UIAction(title: "Share PDF File",image: UIImage(systemName: "doc.text.image.fill")) { _ in
            self.shareTableView("pdf")
        }
        topMenu = UIMenu(title: "Share selection", image: UIImage(systemName: "square.and.arrow.up"), options: .singleSelection , children: [shareImage,sharePDF])
    }
    
    func shareTableView(_ typeSharing: String) {
        //pdf render
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: tableView.bounds)
        let pdfData = pdfRenderer.pdfData { context in
            context.beginPage()
            tableView.drawHierarchy(in: tableView.bounds, afterScreenUpdates: true)
        }
        //screenshot render
        UIGraphicsBeginImageContextWithOptions(tableView.contentSize, false, 0.0)
        tableView.layer.render(in: UIGraphicsGetCurrentContext()!)
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            alertError(text: "Error making screenshot of table view", mainTitle: "Error!")
            return
        }
        UIGraphicsEndImageContext()
        var activityItems = [Any]()
        if typeSharing == "image" {
            activityItems.append(image)
        } else {
            activityItems.append(pdfData)
        }
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        self.present(activityViewController, animated: true, completion: nil)
        
    }
    
    private func checkPlannedNotification() -> Bool {
        var value = Bool()
        let center = UNUserNotificationCenter.current()
        let date = selectedScheduleModel.scheduleDate!
        print(date)
        center.getPendingNotificationRequests { requests in
            let notOnDate = requests.filter { request in
                if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                    return Calendar.current.isDate(trigger.nextTriggerDate()!, inSameDayAs: date)
                }
                return false
            }
            if notOnDate.count > 0 {
                print("there are \(notOnDate.count) notifications planned for \(date)")
                value = true
            } else {
                print("No notification on current day")
                value = false
            }
        }
        return value
    }

}
//MARK: - table view delegates and data sources
extension OpenTaskDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 2
        case 2: return 4
        case 3: return 1
        default: return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let inheritedData = selectedScheduleModel
        let data = cellsName[indexPath.section][indexPath.row]
        let time = DateFormatter.localizedString(from: inheritedData.scheduleTime ?? Date(), dateStyle: .none, timeStyle:.short)
        let date = DateFormatter.localizedString(from: inheritedData.scheduleDate ?? Date(), dateStyle: .medium, timeStyle:.none)
        
        
        cell.backgroundColor = UIColor(named: "cellColor")
        cell.textLabel?.numberOfLines = 0
        
        let switchButton = UISwitch(frame: .zero)
        switchButton.isOn = false
        switchButton.isHidden = true
        switchButton.onTintColor = UIColor(named: "navigationControllerColor")
        cell.accessoryView = switchButton
        
        switch indexPath {
        case [0,0]:
            cell.textLabel?.text = inheritedData.scheduleName
        case [1,0]:
            cell.textLabel?.text = date + " Time: " + time
        case [1,1]:
//            let content = UNMutableNotificationContent()
//            if content.userInfo["userNotification"] as? String == date {
//                switchButton.isOn = true
//            } else {
//                switchButton.isOn = false
//            }
//            let value = checkPlannedNotification()
//            if value {
//                switchButton.isOn = value
//            } else {
//                switchButton.isOn = value
//            }
            cell.textLabel?.text = "Reminder status"
            cell.accessoryView?.isHidden = false
            switchButton.isEnabled = false
        case[2,0]:
            cell.textLabel?.text = inheritedData.scheduleCategoryName ?? data
        case [2,1]:
            cell.textLabel?.text = inheritedData.scheduleCategoryType ?? data
        case [2,2]:
            cell.textLabel?.text = inheritedData.scheduleCategoryURL ?? data
            let text = inheritedData.scheduleCategoryURL

            if let success = text?.isURLValid(text: text ?? "") , !success {
                cell.textLabel?.textColor = .systemBlue
            } else {
                cell.textLabel?.textColor = UIColor(named: "textColor")
            }
        case [2,3]:
            cell.textLabel?.text = inheritedData.scheduleCategoryNote ?? data
        case [3,0]:
            cell.backgroundColor = UIColor.color(withData: (inheritedData.scheduleColor)!)
        case [4,0]:
            cell.textLabel?.text = data
            cell.accessoryView?.isHidden = false
            switchButton.isOn = inheritedData.scheduleRepeat ?? false
            switchButton.isEnabled = false
        default:
            alertError(text: "Please,try again later\nError getting data", mainTitle: "Error!!")
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath == [2,2] {
            guard let url = selectedScheduleModel.scheduleCategoryURL else { return }
            futureUserActions(link: url)
        } else {
            tableView.allowsSelection = false
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return headerArray[section]
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        5
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
}

extension OpenTaskDetailViewController {
    private func setupConstraints(){
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        view.addSubview(indicator)
        indicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-60)
            make.width.height.equalTo(50)
        }
    }
}
