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
import WidgetKit

class ScheduleViewController: UIViewController, CheckSuccessSaveProtocol{
    
    private let localRealm = try! Realm()
    private var scheduleModel: Results<ScheduleModel>!
    private var filteredModel: Results<ScheduleModel>!
    private var birthdayModel: [Date] = []
    private var filteredContactData: Results<ContactModel>!
    private var filteredScheduleModel: Results<ScheduleModel>!
    
    //MARK: - UI elements setups
    private lazy var searchNavigationButton: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage(systemName: "magnifyingglass.circle.fill"), landscapeImagePhone: nil, style: .plain, target: self, action: #selector(didTapSearch))
    }()
    
    private lazy var createNewEventNavigationButton: UIBarButtonItem = {
        return UIBarButtonItem(title: nil, image: UIImage(systemName: "plus.circle.fill"), target: self, action: #selector(didTapCreate))
    }()
    
    private lazy var displayAllEvent: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage(systemName: "list.bullet.circle.fill"), landscapeImagePhone: nil, style: .done, target: self, action: #selector(didTapOpenAllEvent))
    }()
    
    private var calendar: FSCalendar = {
       let calendar = FSCalendar()
        calendar.formatter.timeZone = TimeZone.current
        calendar.scrollDirection = .vertical
        calendar.backgroundColor = UIColor(named: "backgroundColor")
        calendar.tintColor = UIColor(named: "navigationControllerColor")
        calendar.locale = .current
        calendar.pagingEnabled = false
        calendar.weekdayHeight = 30
        calendar.headerHeight = 50
        calendar.firstWeekday = 2
        calendar.placeholderType = .none //remove past and future dates of months
        calendar.appearance.eventDefaultColor = .systemBlue
        calendar.appearance.borderDefaultColor = .clear
        calendar.appearance.titleWeekendColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        calendar.appearance.titleDefaultColor = UIColor(named: "textColor")
        calendar.appearance.weekdayTextColor = UIColor(named: "calendarHeaderColor")
        calendar.appearance.headerTitleColor = UIColor(named: "calendarHeaderColor")
        calendar.appearance.titleWeekendColor = UIColor(named: "textColor")
        calendar.translatesAutoresizingMaskIntoConstraints = false
        return calendar
    }()
    
    private let searchController: UISearchController = {
       let search = UISearchController(searchResultsController: ScheduleSearchResultViewController())
        search.searchBar.placeholder = "Enter the name of event".localized()
        search.isActive = false
        search.searchBar.searchTextField.clearButtonMode = .whileEditing
        search.obscuresBackgroundDuringPresentation = false
        return search
    }()
    
    //MARK: - Setup for views
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAuthentification()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _ = UserDefaultsManager.shared.checkDarkModeUserDefaults()
        checkPasswordEntryEnable()
        calendar.reloadData()
        tabBarController?.tabBar.isHidden = false
    }
    
   //MARK: - target methods
    
    @objc private func didTapSearch(){
        setupHapticMotion(style: .rigid)
        navigationItem.searchController = searchController
        searchController.isActive = true
    }
    
    @objc private func didTapCreate(){
        setupHapticMotion(style: .rigid)
        let vc = CreateEventScheduleViewController(choosenDate: Date())
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        nav.modalTransitionStyle = .flipHorizontal
        nav.isNavigationBarHidden = false
        present(nav, animated: isViewAnimated) { [unowned self] in
            self.calendar.reloadData()
            self.setupView()
        }
    }
    
    @objc private func didTapOpenAllEvent(){
        setupHapticMotion(style: .soft)
        let vc = ScheduleAllEventViewController(model: scheduleModel)
        navigationController?.pushViewController(vc, animated: isViewAnimated)
    }
    
    //MARK: - Setup Methods
    private func setupView(){
        isSavedCompletely(boolean: false)
        loadingData()
        calendar.reloadData()
        setupDelegates()
        setupConstraints()
        setupSearchController()
        calendarDidBeginScrolling(calendar)
        
        loadingDataByDate(date: Date(), at: .current, is: true)
        view.backgroundColor = UIColor(named: "backgroundColor")
        calendar.appearance.titleFont = .setMainLabelFont()
        calendar.appearance.weekdayFont = .setMainLabelFont()
        calendar.appearance.headerTitleFont = .setMainLabelFont()
    }
    
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
        if !UserDefaults.standard.bool(forKey: "isAuthorised"){
            let vc = AuthenticationViewController()
            let navVC = UINavigationController(rootViewController: vc)
            navVC.modalPresentationStyle = .fullScreen
            navVC.isNavigationBarHidden = false
            present(navVC, animated: isViewAnimated)
            setupView()
            setupNavigationController()
        } else {
            setupView()
            setupNavigationController()
        }
    }
    
    
    private func checkPasswordEntryEnable(){
        let success = UserDefaults.standard.bool(forKey: "isPasswordCodeEnabled")
        let isAuthorized = UserDefaults.standard.bool(forKey: "isUserConfirmPassword")
        if success && !isAuthorized {
            let vc = UserProfileSwitchPasswordViewController(isCheckPassword: true)
            vc.modalPresentationStyle = .overCurrentContext
            tabBarController?.present(vc, animated: isViewAnimated)
            navigationController?.pushViewController(vc, animated: isViewAnimated)
        }
    }
    
    private func setupNavigationController(){
        title = "Calendar".localized()
        navigationItem.leftBarButtonItems = [searchNavigationButton]
        navigationItem.rightBarButtonItems = [createNewEventNavigationButton,displayAllEvent]
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        navigationController?.navigationBar.tintColor = UIColor(named: "calendarHeaderColor")
        navigationController?.navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = false
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
        
        let birthdayDates = localRealm.objects(ContactModel.self)
        for contact in birthdayDates {
            if let birthdayDate = contact.contactDateBirthday {
                self.birthdayModel.append(birthdayDate)
            }
        }
        let dates: [Date] = birthdayDates.compactMap({ $0.contactDateBirthday })
        
        birthdayModel = dates
    }
    
    private func calendarDidBeginScrolling(_ calendar: FSCalendar){
        guard let date = calendar.selectedDate else { return }
        calendar.deselect(date)
    }

    /// Setup function for loading data from Realm model by date predicate and other filters and assings loaded data to realm value
    /// - Parameters:
    ///   - date: sending current date
    ///   - monthPosition: current position of month in calendar
    ///   - firstLoad: boolean value which check if application launch at first time
    private func loadingDataByDate(date: Date,at monthPosition: FSCalendarMonthPosition,is firstLoad: Bool) {
        let dateStart = date
        let dateEnd: Date = {
            let components = DateComponents(day:1, second: -1)
            return Calendar.current.date(byAdding: components, to: dateStart)!
        }()
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekday], from: date)
        guard let weekday = components.weekday else {
            alertError(text: "Can't get weekday numbers. Try again!".localized(), mainTitle: "Error value".localized())
            return
        }
        
        
        let value = localRealm.objects(ScheduleModel.self)
        scheduleModel = value
        let userDefaults = UserDefaults(suiteName: "group.widgetGroupIdentifier")//value needed for sending data to WidgetKit
    
        let currentDatePredicate = NSPredicate(format: "scheduleStartDate BETWEEN %@", [dateStart,dateEnd])
        let filteredValue = localRealm.objects(ScheduleModel.self).filter(currentDatePredicate)
        userDefaults?.setValue(filteredValue.count, forKey: "group.integer")
        WidgetCenter.shared.reloadAllTimelines()
        openChosenDate(firstLoad: firstLoad, monthPosition: .current, weekday: weekday, dateStart: dateStart, dateEnd: dateEnd)
        
        let valueContact = localRealm.objects(ContactModel.self)
        
        filteredContactData = valueContact
        
    }
    
    
    /// Function for open Create Task View controller with sending to next controller realm model data
    /// - Parameters:
    ///   - firstLoad: boolean value check if app launch at first time
    ///   - monthPosition: position of selected month
    ///   - weekday: number of weekday(from 0..6)
    ///   - dateStart: start date which use for predicate
    ///   - dateEnd: end date which use for predicate
    private func openChosenDate(firstLoad: Bool,monthPosition: FSCalendarMonthPosition,weekday: Int,dateStart: Date,dateEnd: Date){
        if firstLoad == false {
            if monthPosition == .current {
                let predicate = NSPredicate(format: "scheduleWeekday = \(weekday)")
                let predicateUnrepeat = NSPredicate(format: "scheduleStartDate BETWEEN %@", [dateStart,dateEnd])
                let compound = NSCompoundPredicate(type: .or, subpredicates: [predicate,predicateUnrepeat])
                let value = localRealm.objects(ScheduleModel.self).filter(compound)
                let vc = CreateTaskForDayController(model: value, choosenDate: dateStart)
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                nav.isNavigationBarHidden = false
                present(nav, animated: isViewAnimated)
            }
        }
    }
    
    //MARK: - Check Success Protocol delegate
    func isSavedCompletely(boolean: Bool) {
        if boolean {
            showAlertForUser(text: "Event saved successfully".localized(), duration: DispatchTime.now()+1, controllerView: view)
            loadingData()
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
        setupHapticMotion(style: .soft)
        loadingDataByDate(date: date, at: monthPosition, is: false)
    }
    
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        calendar.deselect(calendar.selectedDate ?? Date())
    }
    
    
    
    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        var eventCounts = [String: Int]()
        var birthdayCounts = [String: Int]()
        
        for birthday in filteredContactData {
            if let model = birthday.contactDateBirthday {
                let convertedModel = model.getDateWithoutYear(currentYearDate: date)
                let dateString = DateFormatter.localizedString(from: convertedModel, dateStyle: .medium, timeStyle: .none)
                if birthdayCounts[dateString] != nil {
                    birthdayCounts[dateString]! += 1
                } else {
                   birthdayCounts[dateString] = 1
                }
            }
        }

        for event in scheduleModel {
            let dateModel = event.scheduleStartDate ?? Date()
            let date = DateFormatter.localizedString(from: dateModel, dateStyle: .medium, timeStyle: .none)
            if eventCounts[date] != nil {
                eventCounts[date]! += 1
            } else {
                eventCounts[date] = 1
            }
        }
        
        

        let convertDate = DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
//        calendar.appearance.eventDefaultColor = .systemBlue
        if eventCounts[convertDate] != nil && birthdayCounts[convertDate] != nil{
            return 2
        } else if eventCounts[convertDate] != nil {
            return 1
        } else if birthdayCounts[convertDate] != nil {
            return 1
        } else {
            return 0
        }
    }
}

extension ScheduleViewController: FSCalendarDelegateAppearance {
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, eventDefaultColorsFor date: Date) -> [UIColor]? {
        var colors: [UIColor] = []
        let birthdayModel = localRealm.objects(ContactModel.self)
        for contact in birthdayModel {
            if let dateB = contact.contactDateBirthday {
                let dayB = Calendar.current.component(.day, from: dateB)
                let monthB = Calendar.current.component(.month, from: dateB)
                
                let day = Calendar.current.component(.day, from: date)
                let month = Calendar.current.component(.month, from: date)
                
                if dayB == day && monthB == month {
                    colors.append(.systemRed)
                }
            }
        }
        
        let startDate = date
        let endDate: Date = {
           let comp = DateComponents(day: 1,second: -1)
            return Calendar.current.date(byAdding: comp, to: startDate)!
        }()
        
        let scheduleModel = localRealm.objects(ScheduleModel.self).filter("scheduleStartDate BETWEEN %@", [startDate,endDate])
        
        if !scheduleModel.isEmpty {
            colors.append(.systemBlue)
        }
        
        return colors
    }
}
//MARK: - Search delegates
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
        searchBar.resignFirstResponder()
        searchController.isActive = false
    }

    func filterTable(_ text: String) -> Results<ScheduleModel>{
        loadingData()
        let predicate = NSPredicate(format: "scheduleName CONTAINS[c] %@", text)
        filteredModel = filteredModel.filter(predicate).sorted(byKeyPath: "scheduleStartDate")
        return filteredModel ?? scheduleModel
    }
}

//MARK: - extensions with contstraints setups
extension ScheduleViewController {
    private func setupConstraints(){
        view.addSubview(calendar)
        calendar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(0)
            make.leading.trailing.equalToSuperview().inset(0)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(0)
        }
    }
}

