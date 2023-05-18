//
//  ScheduleViewController.swift
//  ForgetAboutTasks
//
//  Created by Константин Малков on 09.03.2023.
/*
 class with displaying calendar and some events
 */

import UIKit
import FSCalendar
import EventKit
import SnapKit
import RealmSwift

class ScheduleViewController: UIViewController {
    
    let formatter = Formatters()
    
    let localRealm = try! Realm()
    private var scheduleModel: Results<ScheduleModel>!
    private var filteredModel: Results<ScheduleModel>!
    
    let resultVC = ScheduleSearchResultViewController()
    
    private lazy var searchNavigationButton: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage(systemName: "magnifyingglass.circle.fill"), landscapeImagePhone: nil, style: .plain, target: self, action: #selector(didTapSearch))
    }()
    
    private let tableView = UITableView()
    
    private var calendar: FSCalendar = {
       let calendar = FSCalendar()
        calendar.formatter.timeZone = TimeZone.current
        calendar.scrollDirection = .vertical
        calendar.backgroundColor = UIColor(named: "backgroundColor")
        calendar.tintColor = UIColor(named: "navigationControllerColor")
        calendar.locale = Locale(identifier: "en")
        calendar.pagingEnabled = false
        calendar.weekdayHeight = 30
        calendar.headerHeight = 50
        calendar.firstWeekday = 2
        calendar.placeholderType = .none //remove past and future dates of months
        calendar.appearance.eventDefaultColor = #colorLiteral(red: 0.8374214172, green: 0.8374213576, blue: 0.8374213576, alpha: 1)
        calendar.appearance.titleFont = UIFont.systemFont(ofSize: 18)
        calendar.appearance.headerTitleFont = .systemFont(ofSize: 20)
        calendar.appearance.borderDefaultColor = .clear
        calendar.appearance.titleWeekendColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        calendar.appearance.titleDefaultColor = UIColor(named: "textColor")
        calendar.appearance.weekdayTextColor = UIColor(named: "calendarHeaderColor")
        calendar.appearance.headerTitleColor = UIColor(named: "calendarHeaderColor")
        calendar.tintColor = UIColor(named: "navigationControllerColor")
        calendar.translatesAutoresizingMaskIntoConstraints = false
        return calendar
    }()
    
    private let searchController: UISearchController = {
       let search = UISearchController(searchResultsController: ScheduleSearchResultViewController())
        search.searchBar.placeholder = "Enter the name of event"
        search.isActive = false
        search.searchBar.searchTextField.clearButtonMode = .whileEditing
        search.obscuresBackgroundDuringPresentation = false
        return search
    }()
    
    //MARK: - Setup for views
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAuthentification()
        calendar.transform = CGAffineTransform(translationX: 0.01, y: 0.01)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupAnimation()
    }
    
   //MARK: - target methods
    @objc private func didTapSearch(){
            navigationItem.searchController = searchController
            searchController.isActive = true
    }
    
    @objc private func selectDate(_ sender: Any){
        
    }
    
    @objc private func didTapCallAlert(){
//        showAlertForUser(text: "View was loaded", duration: DispatchTime.now()+2, controllerView: view)
    }
    
    

    //MARK: - Setup Methods
    private func setupDelegates(){
        calendar.delegate = self
        calendar.dataSource = self
    }
    
    private func setupAnimation(){
        UIView.animate(withDuration: 1, delay: 0, options: .curveLinear) {
            self.calendar.transform = CGAffineTransform.identity
            self.view.layoutIfNeeded()
        }
    }
    
    private func setupAuthentification(){
        if CheckAuth.shared.isNotAuth() {
            let vc = UserAuthViewController()
            let navVC = UINavigationController(rootViewController: vc)
            navVC.modalPresentationStyle = .fullScreen
            navVC.isNavigationBarHidden = false
            present(navVC, animated: true)
            setupView()
            setupNavigationController()
        } else {
            setupView()
            setupNavigationController()
        }
    }
    
    private func setupView(){
        calendar.reloadData()
        setupDelegates()
        setupConstraints()
        setupSearchController()
        loadingData()
        setupTableView()
        loadingDataByDate(date: Date(), at: .current, is: true)
        view.backgroundColor = UIColor(named: "backgroundColor")
    }
    
    private func setupTableView(){
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isHidden = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "scheduleCell")
    }
    
    private func setupNavigationController(){
        title = "Schedule"
        navigationItem.leftBarButtonItem = searchNavigationButton
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        navigationController?.navigationBar.tintColor = UIColor(named: "navigationControllerColor")
        navigationController?.tabBarController?.tabBar.scrollEdgeAppearance = navigationController?.tabBarController?.tabBar.standardAppearance
        navigationController?.navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(didTapCallAlert))
    }
    
    private func setupSearchController(){
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = nil
        navigationItem.hidesSearchBarWhenScrolling = true
    }
    
    private func loadingData(){
        let value = localRealm.objects(ScheduleModel.self)
        filteredModel = value
    }
    
    private func loadingDataByDate(date: Date,at monthPosition: FSCalendarMonthPosition,is firstLoad: Bool) {
        let dateStart = date
        let dateEnd: Date = {
            let components = DateComponents(day:1, second: -1)
            return Calendar.current.date(byAdding: components, to: dateStart)!
        }()
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekday], from: date)
        guard let weekday = components.weekday else { alertError(text: "", mainTitle: "Error value");return }
        
        
        let value = localRealm.objects(ScheduleModel.self)
        scheduleModel = value
        

        if firstLoad == false {
            if monthPosition == .current {
                let predicate = NSPredicate(format: "scheduleWeekday = \(weekday) AND scheduleRepeat = true")
                let predicateUnrepeat = NSPredicate(format: "scheduleRepeat = false AND scheduleDate BETWEEN %@", [dateStart,dateEnd])
                let compound = NSCompoundPredicate(type: .or, subpredicates: [predicate,predicateUnrepeat])
                let value = localRealm.objects(ScheduleModel.self).filter(compound)
                let vc = CreateTaskForDayController()
                vc.choosenDate = date
                vc.cellDataScheduleModel = value
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                nav.isNavigationBarHidden = false
                present(nav, animated: true)
            }
        }
    }
}
//MARK: - calendar delegates
extension ScheduleViewController: FSCalendarDelegate, FSCalendarDataSource {
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        calendar.snp.updateConstraints { make in
            make.height.equalTo(bounds.height)
        }
        self.view.layoutIfNeeded()
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        loadingDataByDate(date: date, at: monthPosition, is: false)
        print(String(describing: date))
    }
    
    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        var eventCounts = [Date: Int]()
        for event in scheduleModel {
            let date = event.scheduleDate ?? Date()
            print(date)
            if let count = eventCounts[date]{
                eventCounts[date]! += 1
            } else {
                eventCounts[date] = 1
            }
        }
        if let counts = eventCounts[date] {
            return counts

        } else {
            return 0
        }
    }
}
//MARK: - Table view Delegates and DataSources
extension ScheduleViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredModel?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "scheduleCell")
        cell.textLabel?.text = filteredModel?[indexPath.row].scheduleName
        cell.detailTextLabel?.text = String(describing: filteredModel?[indexPath.row].scheduleDate)
        return cell
    }
}



extension ScheduleViewController: UISearchResultsUpdating,UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { alertError();return }
        let value = filterTable(text)
        if !text.isEmpty {
            let vc = searchController.searchResultsController as? ScheduleSearchResultViewController
            vc?.scheduleModel = value
            vc?.tableView.reloadData()
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if ((searchBar.text?.isEmpty) != nil) {
            tableView.isHidden = true
            calendar.isHidden = false
        }
    }

    func filterTable(_ text: String) -> Results<ScheduleModel>{
        loadingData()
        let predicate = NSPredicate(format: "scheduleName CONTAINS[c] %@", text)
        filteredModel = filteredModel.filter(predicate).sorted(byKeyPath: "scheduleDate")
        return filteredModel ?? scheduleModel
    }
}



extension ScheduleViewController {
    private func setupConstraints(){
        view.addSubview(calendar)
        calendar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(0)
            make.leading.trailing.equalToSuperview().inset(0)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(0)
        }
        view.addSubview(tableView)
            tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
}

