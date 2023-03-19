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

class ScheduleViewController: UIViewController {
    
    var dateDictionary: [String: [TasksDate]] = [:]
    
    let formatter = Formatters()
    
    
    private var calendar: FSCalendar = {
       let calendar = FSCalendar()
        calendar.scrollDirection = .vertical
        calendar.backgroundColor = .systemOrange
        calendar.locale = Locale(identifier: "ru_RU")
        calendar.pagingEnabled = false
        calendar.weekdayHeight = 30
        calendar.headerHeight = 50
        calendar.firstWeekday = 2
        calendar.translatesAutoresizingMaskIntoConstraints = false
        return calendar
    }()
    
    private let hideButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Open Calendar", for: .normal)
        button.setTitleColor(#colorLiteral(red: 0.04713427275, green: 0.08930709213, blue: 0.1346856952, alpha: 1), for: .normal)
        button.titleLabel?.font = UIFont(name: "Avenir Next Demi Bold", size: 16)
        button.backgroundColor = #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNavigationController()
    }
    
   //MARK: - target methods
    @objc private func didTapTapped(){
        if !calendar.pagingEnabled {
            calendar.pagingEnabled = true
            navigationItem.leftBarButtonItem?.image = UIImage(systemName: "eye.slash.fill")
        } else {
            calendar.pagingEnabled = false
            navigationItem.leftBarButtonItem?.image = UIImage(systemName: "eye.fill")
        }
    }
    
    @objc private func didTapSetting(){
        let vc = OptionsForScheduleViewController()
        let navVC = UINavigationController(rootViewController: vc)
        navVC.isNavigationBarHidden = false
        navVC.modalPresentationStyle = .fullScreen
        navVC.modalTransitionStyle = .crossDissolve
        present(navVC, animated: true)
        
    }
    //MARK: - Setup Methods
    private func setupDelegates(){
        let tasks = TasksViewController()
        tasks.delegate = self
        calendar.delegate = self
        calendar.dataSource = self
    }
    
    private func setupView(){
        setupDelegates()
        setupConstraints()
        view.backgroundColor = .systemBackground
    }
    
    private func setupNavigationController(){
        title = "Schedule"
        navigationController?.navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "eye.fill"), landscapeImagePhone: nil, style: .done, target: self, action: #selector(didTapTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "gearshape.fill"), landscapeImagePhone: nil, style: .done, target: self, action: #selector(didTapSetting))
    }
}
//MARK: - Tasks Delegate
extension ScheduleViewController: TasksViewDelegate {
    func tasksData(array data: [TasksDate], date: String) {
        if !data.isEmpty {
            dateDictionary[date] = data
            self.calendar.reloadData()
        } else {
            dateDictionary.removeValue(forKey: date)
            self.calendar.reloadData()
        }
    }
}


//MARK: - calendar delegates
extension ScheduleViewController: FSCalendarDelegate, FSCalendarDataSource {
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        calendar.frame.size.height = bounds.height
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        
        if date == .now {
            
        }
        if monthPosition == .current {
            
            let dateString = formatter.stringFromDate(date: date)
            print(dateString)
            let vc = TasksViewController()
            vc.delegate = self
            vc.choosenDate = date
            if let dict = dateDictionary[dateString] {
                vc.cellData = dict
            }
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            nav.isNavigationBarHidden = false
            present(nav, animated: true)
        }
    }
    
    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        
        let string = formatter.stringFromDate(date: date)
        if self.dateDictionary[string] != nil && self.dateDictionary[string]?.count == 1 {
            return 1
        } else if self.dateDictionary[string]?.count == 2 {
            return 2
        } else if let count = self.dateDictionary[string]?.count   {
            if count >= 3 {
                return 3
            }
        }
        return 0
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
    }
}

//MARK: - Добавление евентов в календарь для отображения
//    var dates = ["2023-03-10","2023-03-11","2023-03-12","2023-03-13","2023-03-14","2023-03-15"]
//



//    private func setupSwipeAction(){
//        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(didTapSwipe))
//        swipeUp.direction = .up
//        calendar.addGestureRecognizer(swipeUp)
//
//        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(didTapSwipe))
//        swipeDown.direction = .up
//        calendar.addGestureRecognizer(swipeDown)
//    }
    
//    @objc private func didTapSwipe(gesture: UISwipeGestureRecognizer){
//        switch gesture.direction {
//        case .up:
//            didTapTapped()
//        case .down:
//            didTapTapped()
//        default:
//            break
//        }
//    }

