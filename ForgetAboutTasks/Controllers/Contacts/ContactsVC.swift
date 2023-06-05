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
import Contacts
import ContactsUI


class ContactsViewController: UIViewController , CheckSuccessSaveProtocol{
    
    private var contactData: Results<ContactModel>!
    private var filteredContactData: Results<ContactModel>!
    private var localRealmData = try! Realm()
    
//MARK: - UI elements
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
    
    private lazy var importContacts: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.down"), style: .done, target: self, action: #selector(didTapOpenContacts))
    }()
    
    private let contactPicker = CNContactPickerViewController()
//MARK: - Views loading
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationController()
        UIView.transition(with: tableView, duration: 0.3,options: .transitionCrossDissolve) {
            self.tableView.reloadData()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupView()
    }

    //MARK: - Targets methods
    @objc private func didTapCreateNewContact(){
        let vc = NewContactViewController()
        vc.delegate = self
        show(vc, sender: nil)
    }
    
    @objc private func didTapOpenContacts(){
        let vc = contactPicker
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated:  true)
    }
    //MARK: - Setup methods
    private func setupView() {
        isSavedCompletely(boolean: false)
        setupConstraints()
        setupSearchController()
        loadingRealmData()
        contactPicker.delegate = self
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
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapCreateNewContact))
        navigationItem.rightBarButtonItems = [addButton,importContacts]
        navigationController?.navigationBar.tintColor = UIColor(named: "navigationController")
        navigationController?.navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.tintColor = UIColor(named: "navigationControllerColor")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .done, target: nil, action: nil)
        title = "Contacts"
    }
    //MARK: -Loading methods
    private func loadingRealmData(typeOf sort: String = "contactName") {
        let secValue = localRealmData.objects(ContactModel.self).sorted(byKeyPath: sort)
        contactData = secValue
        self.tableView.reloadData()
    }
    
    private func openCurrentContact(model: ContactModel,boolean: Bool){
        let vc = EditContactViewController(contactModel: model,editing: boolean)
        vc.delegate = self
        show(vc, sender: nil)
    }
    
    private func actionsWithContact(model: ContactModel){
        let name = String(describing: model.contactName)
        let phone = String(describing: model.contactPhoneNumber)
        let alert = UIAlertController(title: nil, message: "What exactly do you want?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Contact Details", style: .default,handler: { [weak self] _ in
            self?.openCurrentContact(model: model,boolean: false)
        }))
        alert.addAction(UIAlertAction(title: "Call to \(name)", style: .default,handler: { [weak self] _ in
            guard let url = URL(string: "tel://\(phone)") else { self?.alertError();return}
            if UIApplication.shared.canOpenURL(url){
                UIApplication.shared.open(url)
            } else {
                self?.alertError(text: "This function is not avaliable.\nTry again later", mainTitle: "Error!")
            }
        }))
        alert.addAction(UIAlertAction(title: "Write message", style: .default,handler: { [weak self] _ in
            if MFMessageComposeViewController.canSendText() {
                let vc = MFMessageComposeViewController()
                vc.body = "Hello!"
                vc.recipients = ["\(phone)"]
                vc.messageComposeDelegate = self
                
                self?.show(vc, sender: nil)
            } else {
                self?.alertError(text: "This function is not avaliable.\nTry again later", mainTitle: "Error!")
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    func isSavedCompletely(boolean: Bool) {
        if boolean {
            showAlertForUser(text: "Contact saved successfully", duration: DispatchTime.now()+1, controllerView: view)
        }
    }
    
    func importContact(contacts: [CNContact]){
        for contact in contacts {
            let model = ContactModel()
            guard let phone = contact.phoneNumbers.first?.value else { alertError(text: "Can't get data from Contacts", mainTitle: "Error"); return}
            let email = contact.emailAddresses.first?.value
            let numberPhone = CNPhoneNumber(stringValue: phone.stringValue).stringValue
            let emailString = email as? String
            model.contactImage = contact.imageData
            model.contactName = contact.givenName + " " + contact.familyName + " " + contact.middleName
            model.contactPhoneNumber = numberPhone
            model.contactMail = emailString
            
            
            ContactRealmManager.shared.saveContactModel(model: model)
            tableView.reloadData()
            showAlertForUser(text: "Choosen contact imported successfully", duration: DispatchTime.now()+1, controllerView: view)
        }
    }

    
}
//MARK: - Contacts delegate
extension ContactsViewController: CNContactPickerDelegate {
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
        importContact(contacts: contacts)
    }
}

//MARK: - Search delegates
extension ContactsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterTable(searchController.searchBar.text ?? "Empty value")
    }
    
    private func filterTable(_ searchText: String) {
        filteredContactData = contactData.filter("contactName CONTAINS[c] %@ ",searchText)
        tableView.reloadData()
    }

    
}
//MARK: - Table view delegates
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
        
        let number = String.format(with: "+X (XXX) XXX-XXXX", phone: data.contactPhoneNumber ?? "Enter phone number")
        
        cell.textLabel?.text = data.contactName
        cell.detailTextLabel?.text = "Phone number: " + number
        cell.imageView?.image = UIImage(systemName: "person.crop.circle.fill")
        cell.imageView?.frame(forAlignmentRect: CGRect(x: 0, y: 0, width: 50, height: 50))
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let cellData = contactData[indexPath.row]
        let detailInstance = UIContextualAction(style: .normal, title: "") { [weak self] _, _, handler in
            self?.openCurrentContact(model: cellData,boolean: false)
        }
        detailInstance.backgroundColor = .lightGray
        detailInstance.image = UIImage(systemName: "ellipsis")
        detailInstance.image?.withTintColor(.systemBackground)
        let action = UISwipeActionsConfiguration(actions: [detailInstance])
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
//MARK: - Message delegate for opening mail
extension ContactsViewController: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        if result == .cancelled {
            self.dismiss(animated: true)
        }
    }
    
    
}
//MARK: - setup constraints
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
