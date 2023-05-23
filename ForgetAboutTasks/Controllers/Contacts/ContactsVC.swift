//
//  ContactsViewController.swift
//  ForgetAboutTasks
//
//  Created by Константин Малков on 09.03.2023.
//

import UIKit
import SnapKit
import RealmSwift
import MessageUI


class ContactsViewController: UIViewController {
    
    var contactData: Results<ContactModel>!
    var filteredContactData: Results<ContactModel>!
    private var localRealmData = try! Realm()
    
    private var searchBarIsEmpty: Bool {
        guard let text = searchController.searchBar.text else { return true }
        return text.isEmpty
    }
    
    private var viewIsFiltered: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }
    
    private let searchController = UISearchController()
    private let tableView = UITableView()
    
    private let refreshController: UIRefreshControl = {
       let controller = UIRefreshControl()
        controller.tintColor = #colorLiteral(red: 0.3555810452, green: 0.3831118643, blue: 0.5100654364, alpha: 1)
        controller.attributedTitle = NSAttributedString(string: "Pull to refresh")
        return controller
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupView()
    }

    //MARK: - Targets methods
    @objc private func didTapCreateNewContact(){
        let vc = UINavigationController(rootViewController: NewContactViewController())
        vc.isNavigationBarHidden = false
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .coverVertical
        present(vc, animated: true)
    }
    //MARK: - Setup methods
    private func setupView() {
        setupNavigationController()
        setupConstraints()
        setupSearchController()
        loadingRealmData()
        view.backgroundColor = UIColor(named: "backgroundColor")
    }
    
    private func setupTableView(){
        tableView.backgroundColor = UIColor(named: "backgroundColor")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "contactCell")
    }

    private func setupSearchController(){
        searchController.searchBar.placeholder = "Search Contacts"
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
    }
    
    private func setupNavigationController(){
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapCreateNewContact))
        navigationController?.navigationBar.tintColor = UIColor(named: "navigationController")
        navigationController?.navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.tintColor = UIColor(named: "navigationControllerColor")
        title = "Contacts"
    }
    //MARK: -Loading methods
    private func loadingRealmData(typeOf sort: String = "contactName") {
        let secValue = localRealmData.objects(ContactModel.self).sorted(byKeyPath: sort)
        contactData = secValue
        self.tableView.reloadData()
    }
    
    private func openCurrentContact(model: ContactModel){
        let vc = NewContactViewController()
        vc.isViewEdited = false
        vc.contactModel = model
        let nav = UINavigationController(rootViewController: vc)
        nav.isNavigationBarHidden = false
        nav.modalPresentationStyle = .pageSheet
        nav.title = model.contactName
        nav.sheetPresentationController?.prefersGrabberVisible = true
        present(nav, animated: true)
    }
    
    private func actionsWithContact(model: ContactModel){
        let alert = UIAlertController(title: nil, message: "What exactly do you want?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Contact Details", style: .default,handler: { [weak self] _ in
            self?.openCurrentContact(model: model)
        }))
        alert.addAction(UIAlertAction(title: "Call to \(model.contactName)", style: .default,handler: { [weak self] _ in
            guard let url = URL(string: "tel://\(model.contactPhoneNumber)") else { self?.alertError();return}
            if UIApplication.shared.canOpenURL(url){
                UIApplication.shared.open(url)
            }
        }))
        alert.addAction(UIAlertAction(title: "Write message", style: .default,handler: { [weak self] _ in
            if MFMessageComposeViewController.canSendText() {
                let vc = MFMessageComposeViewController()
                vc.body = "Hello!"
                vc.recipients = ["\(model.contactPhoneNumber)"]
                vc.messageComposeDelegate = self
                
                self?.present(vc, animated: true)
            } else {
                print("Error")
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

extension ContactsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterTable(searchController.searchBar.text ?? "Empty value")
    }
    
    private func filterTable(_ searchText: String) {
        filteredContactData = contactData.filter("contactName CONTAINS[c] %@ ",searchText)
        tableView.reloadData()
    }

    
}

extension ContactsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (viewIsFiltered ? filteredContactData.count : contactData.count)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "contactCell")
        let data = (viewIsFiltered ? filteredContactData[indexPath.row] : contactData[indexPath.row])

        cell.backgroundColor = UIColor(named: "backgroundColor")
        cell.textLabel?.font = .systemFont(ofSize: 20,weight: .semibold)
        cell.accessoryType = .disclosureIndicator

        cell.imageView?.clipsToBounds = true
        cell.imageView?.frame = .zero
        cell.imageView?.contentMode = .scaleToFill
        cell.imageView?.tintColor = UIColor(named: "navigationControllerColor")
        
        let number = String.format(with: "+X (XXX) XXX-XXXX", phone: data.contactPhoneNumber)
        
        cell.textLabel?.text = data.contactName
        cell.detailTextLabel?.text = "Phone number: " + number
        cell.imageView?.image = UIImage(systemName: "person.crop.circle.fill")
        cell.imageView?.frame(forAlignmentRect: CGRect(x: 0, y: 0, width: 50, height: 50))
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let cell = tableView.cellForRow(at: indexPath)
        let cellData = contactData[indexPath.row]
        let actionInstance = UIContextualAction(style: .normal, title: "") { _, _, completionHandler in
            if cell?.textLabel?.textColor == .lightGray {
                cell?.textLabel?.textColor = .black
                cell?.detailTextLabel?.textColor = .black
                cell?.imageView?.tintColor = .systemBlue
            } else {
                cell?.textLabel?.textColor = .lightGray
                cell?.imageView?.tintColor = .lightGray
                cell?.detailTextLabel?.textColor = .lightGray
            }
        }
        let detailInstance = UIContextualAction(style: .normal, title: "") { [self] _, _, handler in
            openCurrentContact(model: cellData)
        }
        detailInstance.backgroundColor = .systemGray
        detailInstance.image = UIImage(systemName: "ellipsis")
        detailInstance.image?.withTintColor(.systemBackground)
        
        actionInstance.backgroundColor = .systemYellow
        actionInstance.image = UIImage(systemName: "pencil.line")
        actionInstance.image?.withTintColor(.systemBackground)
        let action = UISwipeActionsConfiguration(actions: [actionInstance,detailInstance])
        return action
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let model = contactData[indexPath.row]
        let deleteInstance = UIContextualAction(style: .destructive, title: "") { _, _, _ in
            ContactRealmManager.shared.deleteContactModel(model: model)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        deleteInstance.backgroundColor = .systemRed
        deleteInstance.image = UIImage(systemName: "trash.fill")
        deleteInstance.image?.withTintColor(.systemBackground)
        let action = UISwipeActionsConfiguration(actions: [deleteInstance])
        
        return action
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = contactData[indexPath.row]
        actionsWithContact(model: model)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        80
    }
}

extension ContactsViewController: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        if result == .cancelled {
            self.dismiss(animated: true)
        }
    }
    
    
}

extension ContactsViewController {
        private func setupConstraints(){
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(0)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(0)
        }
    }
}
