//
//  TasksViewController.swift
//  ForgetAboutTasks
//
//  Created by Константин Малков on 09.03.2023.
//

import UIKit
import FSCalendar
import EventKit
import EventKitUI

protocol TasksViewDelegate: AnyObject {
    func tasksData(array data: [TasksDate],date: String)
}

struct TasksDate {
    var date: String
    var dateGetter: Date?
    var startDate: String?
    var endDate: String?
    var name: String
    var event: EKEvent?
    var store: EKEventStore?
}

class TasksViewController: UIViewController {
    
    weak var delegate: TasksViewDelegate?
    
    public var choosenDate = Date()
    var cellData: [TasksDate] = []
    private var isValueWasChanged = Bool()
    private var isTrailingSwipeActionActive = Bool()
    
    
    private var indexOfCell = Int()
    private var isCellEdited = Bool()
    
    private let store = EKEventStore()
    
    
    private var calendar: FSCalendar = {
       let calendar = FSCalendar()
        calendar.scrollDirection = .vertical
        calendar.scope = .week
        calendar.firstWeekday = 2
        calendar.locale = Locale(identifier: "ru_RU")
        calendar.translatesAutoresizingMaskIntoConstraints = false
        return calendar
    }()
    
    private let tableView: UITableView = {
       let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    private let saveButton: UIButton = {
       let button = UIButton()
        button.configuration = .tinted()
        button.configuration?.title = "Сохранить"
        button.configuration?.image = UIImage(systemName: "square.and.arrow.down.fill")
        button.configuration?.imagePlacement = .leading
        button.configuration?.imagePadding = 8
        button.configuration?.baseBackgroundColor = .systemBlue
        button.configuration?.baseForegroundColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNavigationController()
        setupTableViewAndDelegates()
        print(choosenDate)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        calendar.frame = CGRect(x: 10, y: 90, width: view.frame.size.width-20, height: view.frame.size.height/4)
        tableView.frame = CGRect(x: 0, y: calendar.frame.size.height+10, width: view.frame.size.width, height: view.frame.size.height/1.7)
        saveButton.frame = CGRect(x: 30, y: calendar.frame.size.height+20+tableView.frame.size.height, width: view.frame.size.width-60, height: 55)
    }
 //MARK: -  actions targets methods
    @objc private func didTapTapped(){
        if !cellData.isEmpty && isValueWasChanged == true {
            //present alert and saving data
            setupAlertSheet(title: "Warning", subtitle: "What do you want to do with this list?")
        } else {
            self.dismiss(animated: true)
        }
    }
    
    @objc private func didTapCreate(){
        let event = EKEvent(eventStore: self.store)
        event.startDate = choosenDate
        event.endDate = getEndDate(start: choosenDate)
        event.timeZone = TimeZone(identifier: "Europe/Moscow")
        
        let eventVC = EKEventEditViewController()
        
        
        eventVC.event = event
        eventVC.event?.timeZone = TimeZone(identifier: "Europe/Moscow")
        eventVC.eventStore = store
        eventVC.editViewDelegate = self
        present(eventVC, animated: true)
    }
    
    @objc private func didTapSaveReminder(){
        let date = Formatters.instance.stringFromDate(date: choosenDate)
        if cellData.isEmpty {
//            self.delegate?.tasksData(array: [], date: date)
            self.dismiss(animated: true)
        } else {
            self.delegate?.tasksData(array: cellData, date: date)
            self.dismiss(animated: true)
        }
    }
    
    @objc private func didTapEditCell(){
        if self.tableView.isEditing == true {
            tableView.isEditing = false
        } else {
            tableView.isEditing = true
        }
    }
//MARK: - Set up Methods
    private func getEndDate(start date: Date) -> Date? {
        var comp = DateComponents()
        comp.day = 1
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: comp, to: date)
        return endDate
    }
    
    private func setupAlertSheet(title: String,subtitle: String) {
        let date = Formatters.instance.stringFromDate(date: self.choosenDate)
        let sheet = UIAlertController(title: title, message: subtitle, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Discard changes", style: .destructive,handler: { _ in
            self.dismiss(animated: true)
            self.delegate?.tasksData(array: [],date: date)
        }))
        sheet.addAction(UIAlertAction(title: "Save", style: .default,handler: { [self] _ in
            self.delegate?.tasksData(array: cellData, date: date)
            self.dismiss(animated: true)
        }))
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }
    
    private func setupView(){
        view.addSubview(calendar)
        view.addSubview(tableView)
        view.addSubview(saveButton)
        view.backgroundColor = .systemBackground
        calendar.appearance.todayColor = UIColor.systemBlue
        calendar.today =  choosenDate
        askForUsingEvent()
        setupVisibleSaveButton()
        setupTargetActions()
    }
    
    private func setupTableViewAndDelegates(){
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
        tableView.register(UITableViewCell.self
                           , forCellReuseIdentifier: "cell")
        calendar.delegate = self
        calendar.dataSource = self
        let eventEditVC = EKEventEditViewController()
        eventEditVC.editViewDelegate = self
    }
    
    private func setupVisibleSaveButton(){
        if cellData.isEmpty {
            saveButton.isHidden = true
        } else {
            saveButton.isHidden = false
        }
    }
    
    private func setupNavigationController(){
        let convertDate = Formatters.instance.stringFromDate(date: choosenDate)
        title = "Задачи на \(convertDate)"
        
        navigationController?.navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.backward.circle.fill"), landscapeImagePhone: nil, style: .done, target: self, action: #selector(didTapTapped))
        let firstBut = UIBarButtonItem(image: UIImage(systemName: "plus.circle.fill"), landscapeImagePhone: nil, style: .done, target: self, action: #selector(didTapCreate))
        let secondBut = UIBarButtonItem(title: "Edit", style: .done, target: self, action: #selector(didTapEditCell))
        navigationItem.rightBarButtonItems = [firstBut, secondBut]
       
    }
    
    private func setupTargetActions(){
        saveButton.addTarget(self, action: #selector(didTapSaveReminder), for: .touchUpInside)
    }
    
    private func askForUsingEvent(){
        store.requestAccess(to: .event) { success, error in
            if success, error == nil {
                DispatchQueue.main.async {
                    self.setupView()
                }
            } else {
                let alert = UIAlertController(title: "Warning", message: "Please give access to calendar", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default))
                self.present(alert, animated: true)
            }
        }
    }
    

    
}
//MARK: - table delegates and datasource
extension TasksViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cellData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let model = cellData[indexPath.row]
        let colorEvent = model.event?.calendar.cgColor
        let color = UIColor(cgColor: colorEvent!)
        
        cell.accessoryType = .detailButton
        cell.textLabel?.text = "\(model.event?.title ?? ""), категория: \(model.event?.calendar.title ?? "")"
        cell.detailTextLabel?.text = "\(model.startDate ?? "") -> \(model.endDate ?? "")"
        cell.imageView?.image = UIImage(systemName: "circle.fill")
        cell.imageView?.tintColor = color
    
        return cell
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let model = cellData[indexPath.row]
        let vc = EKEventViewController()
        vc.event = model.event
        vc.title = model.name
        vc.delegate = self
        present(UINavigationController(rootViewController: vc), animated: true)
        self.indexOfCell = indexPath.row
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        isValueWasChanged = true
        let index = indexPath.row
        let deleteInstance = UIContextualAction(style: .destructive, title: "") { [self] _, _, _ in
            self.cellData.remove(at: index)
            //доработать!!!
//            do {
//                if let event = cellData[index].event {
//                    try self.store.remove(event, span: .thisEvent, commit: true)
//                }
//            }catch {
//                let alert = UIAlertController(title: "Warning", message: "Can't delete this event. Try again later", preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: "Ok", style: .cancel))
//                present(alert, animated: true)
//            }
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        deleteInstance.backgroundColor = .systemRed
        deleteInstance.image = UIImage(systemName: "trash.fill")
        deleteInstance.image?.withTintColor(.systemBackground)
        let action = UISwipeActionsConfiguration(actions: [deleteInstance])
        
        return action
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        isTrailingSwipeActionActive = true
        let index = indexPath.row
        indexOfCell = index
        isCellEdited = true
        let model = cellData[index]
        let actionInstance = UIContextualAction(style: .normal, title: "") { [weak self] _, _, completionHandler in
            self?.isTrailingSwipeActionActive = false
            let event = EKEvent(eventStore: model.store!)
            event.startDate = model.event?.startDate
            event.endDate = model.event?.endDate
            event.title = model.name
            
            let eventVC = EKEventEditViewController()
            eventVC.event = event
            eventVC.eventStore = model.store
            eventVC.editViewDelegate = self
            self?.present(eventVC, animated: true)
            completionHandler(true)
        }
        actionInstance.backgroundColor = .systemYellow
        actionInstance.image = UIImage(systemName: "pencil.line")
        actionInstance.image?.withTintColor(.systemBackground)
        let action = UISwipeActionsConfiguration(actions: [actionInstance])
        return action
    }
    
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        isTrailingSwipeActionActive = false
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let item = cellData[sourceIndexPath.row]
        cellData.remove(at: sourceIndexPath.row)
        cellData.insert(item, at: destinationIndexPath.row)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: true)
    }
}

//MARK: - calendar delegates
extension TasksViewController: FSCalendarDelegate, FSCalendarDataSource {
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
    }
}

//MARK: - events edit delegate
extension TasksViewController: EKEventEditViewDelegate {
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        if action == .canceled {
            self.dismiss(animated: true)
        } else if action == .saved {
            isValueWasChanged = true
            let dateGetter = controller.event?.startDate
            let stringDate = controller.event?.startDate.formatted(date: .numeric, time: .standard)
            let endDate = controller.event?.endDate.formatted(date: .numeric, time: .standard)
            let date = cellData.first?.date ?? choosenDate.formatted(date: .omitted, time: .shortened)
            print(date)
            let name = controller.event?.title ?? ""
            guard let event = controller.event else { print("Error saving event");return}
            let ekStore = controller.eventStore
            if !cellData.isEmpty && isCellEdited == true{
                cellData.remove(at: indexOfCell)
                isCellEdited = false
            }
            cellData.append(TasksDate(date: date, dateGetter: dateGetter, startDate: stringDate ?? "",endDate: endDate ?? "", name: name, event: event, store: ekStore))
            self.dismiss(animated: true)
            self.indexOfCell = 0
            self.tableView.reloadData()
            
            
        } else {
            print("some error")
        }
    }
}
//MARK: - event delegates
extension TasksViewController: EKEventViewDelegate {
    func eventViewController(_ controller: EKEventViewController, didCompleteWith action: EKEventViewAction) {
        if action == .deleted {
            self.dismiss(animated: true)
        } else if action == .done {
            self.dismiss(animated: true)
            var model = cellData[indexOfCell]
            model.event = controller.event
            model.name = controller.event.title
            self.tableView.reloadData()
        }
    }
    
    
}


//MARK: - constrain extension for dymanic height changing.NOT USING
extension TasksViewController {
    func setupConstraintsForCalendar(){
        view.addSubview(calendar)
        NSLayoutConstraint.activate([
            calendar.topAnchor.constraint(equalTo: view.topAnchor, constant: 90),
            calendar.leadingAnchor.constraint(equalTo: view.leadingAnchor,constant: 0),
            calendar.trailingAnchor.constraint(equalTo: view.trailingAnchor,constant: 0)
        ])
        
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: calendar.bottomAnchor,constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor , constant: 0),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
//            tableView.bottomAnchor.constraint(equalTo: view.topAnchor, constant: 10)
        ])
        
        view.addSubview(saveButton)
        NSLayoutConstraint.activate([
            saveButton.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 10),
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 30),
            saveButton.bottomAnchor.constraint(equalTo: view.bottomAnchor,constant: -90)
        ])
    }
}
