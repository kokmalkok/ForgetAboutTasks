//
//  AllTasksDetailVC.swift
//  ForgetAboutTasks
//
//  Created by Константин Малков on 03.05.2023.
//

import UIKit
import SnapKit
import Combine


class AllTasksDetailViewController: UIViewController {
    
    let headerArray = ["Name","Date","Time","Notes","URL","Color accent"]
    
    var cellsName = [["Name of event"],
                     ["Date"],
                     ["Time"],
                     ["Notes"],
                     ["URL"],
                     [""]]

    var cellBackgroundColor =  #colorLiteral(red: 0.3555810452, green: 0.3831118643, blue: 0.5100654364, alpha: 1)
    var tasksModel = AllTaskModel()
    
    var cancellable: AnyCancellable?//for parallels displaying color in cell and Combine Kit for it
    
    let picker = UIColorPickerViewController()
    
    private let tableView = UITableView()
    
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
        print("Edit")
//        if !(tasksModel.allTaskNameEvent.isEmpty) {
//            AllTasksRealmManager.shared.saveAllTasksModel(model: tasksModel)
//            tasksModel = AllTaskModel()
//            self.dismiss(animated: true)
//        } else {
//            alertError(text: "Enter value in Name cell", mainTitle: "Error saving!")
//        }
        
    }
    //MARK: - Setup methods
    private func setupView() {
        setupNavigationController()
        setupDelegate()
        setupColorPicker()
        setupConstraints()
        view.backgroundColor = UIColor(named: "backgroundColor")
        title = "New task"
    }
    
    private func setupDelegate(){
        picker.delegate = self
    }
    
    private func setupTableView(){
        view.addSubview(tableView)
        tableView.backgroundColor = UIColor(named: "backgroundColor")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "tasksCell")
    }
    
    private func setupColorPicker(){
        picker.selectedColor = UIColor(named: "navigationControllerColor") ?? #colorLiteral(red: 0.3555810452, green: 0.3831118643, blue: 0.5100654364, alpha: 1)
    }
    
    private func setupNavigationController(){
        navigationController?.navigationBar.tintColor = UIColor(named: "navigationControllerColor")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didTapDismiss))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(didTapEdit))
        
        
    }
    //MARK: - Segue methods
    //methods with dispatch of displaying color in cell while choosing color in picker view
    @objc private func openColorPicker(){
        self.cancellable = picker.publisher(for: \.selectedColor) .sink(receiveValue: { color in
            DispatchQueue.main.async {
                self.cellBackgroundColor = color
            }
        })
        self.present(picker, animated: true)
    }
}
//MARK: - Table view delegates
extension AllTasksDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        6
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tasksCell", for: indexPath)
        cell.layer.cornerRadius = 10
        cell.contentView.layer.cornerRadius = 10
        cell.backgroundColor = UIColor(named: "cellColor")
        switch indexPath {
        case [0,0]:
            cell.textLabel?.text = tasksModel.allTaskNameEvent
        case [1,0]:
            cell.textLabel?.text = DateFormatter.localizedString(from: tasksModel.allTaskDate ?? Date(), dateStyle: .medium, timeStyle: .none)
        case [2,0]:
            cell.textLabel?.text = Formatters.instance.timeStringFromDate(date: tasksModel.allTaskTime ?? Date())
        case [3,0]:
            cell.textLabel?.text = tasksModel.allTaskNotes
        case [4,0]:
            cell.textLabel?.text = tasksModel.allTaskURL
        case [5,0]:
            let color = UIColor.color(withData: tasksModel.allTaskColor!)
            cell.backgroundColor = color
        default:
            print("error")
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
//        let cellName = cellsName[indexPath.section][indexPath.row]
//        switch indexPath {
//        case [0,0]:
//            alertTextField(cell: cellName, placeholder: "Enter title of event", keyboard: .default, table: tableView) { [self] text in
//                cellsName[indexPath.section][indexPath.row] = text
//                tasksModel.allTaskNameEvent = text
//            }
//        case [1,0]:
//            alertDate(table: tableView, choosenDate: nil) { [self] _ , date, dateString in
//                cellsName[indexPath.section][indexPath.row] += ": " + dateString
//                tasksModel.allTaskDate = date
//            }
//        case [2,0]:
//            alertTime(table: tableView, choosenDate: Date()) {  [self] date, timeString in
//                cellsName[indexPath.section][indexPath.row] += ": " + timeString
//                tasksModel.allTaskTime = date
//            }
//        case [3,0]:
//            alertTextField(cell: cellName, placeholder: "Enter notes value", keyboard: .default, table: tableView) { [self] text in
//                cellsName[indexPath.section][indexPath.row] = text
//                tasksModel.allTaskNotes = text
//            }
//        case [4,0]:
//            alertTextField(cell: cellName, placeholder: "Enter URL value", keyboard: .default, table: tableView, completion: { [self] text in
//                cellsName[indexPath.section][indexPath.row] = text
//                tasksModel.allTaskURL = text
//            })
//        case [5,0]:
//            openColorPicker()
//        default:
//            print("error")
//        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return headerArray[section]
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        45
    }
    
}

extension AllTasksDetailViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        cellBackgroundColor = color
        let encodeColor = color.encode()
        DispatchQueue.main.async {
            self.tasksModel.allTaskColor = encodeColor
            self.tableView.reloadData()
        }
    }
}

extension AllTasksDetailViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {}
}

extension AllTasksDetailViewController {
    private func setupConstraints(){
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(0)
            make.leading.trailing.equalToSuperview().inset(10)
            make.bottom.equalToSuperview().inset(0)
        }
    }
}