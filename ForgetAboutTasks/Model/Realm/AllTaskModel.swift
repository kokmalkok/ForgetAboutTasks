//
//  AllTaskModel.swift
//  ForgetAboutTasks
//
//  Created by Константин Малков on 16.04.2023.
//

import RealmSwift
import Foundation

class AllTaskModel: Object {
    
    @Persisted var allTaskID = UUID().uuidString
    @Persisted var allTaskNameEvent: String
    @Persisted var allTaskDate: Date?
    @Persisted var allTaskTime: Date?
    @Persisted var allTaskNotes: String?
    @Persisted var allTaskURL: String?
    @Persisted var allTaskColor: Data?
    @Persisted var allTaskCompleted: Bool = false
}
