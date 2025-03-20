import Foundation

enum RecurringFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Bi-Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"
    
    var displayName: String {
        return self.rawValue
    }
    
    var description: String {
        switch self {
        case .daily:
            return "Every day"
        case .weekly:
            return "Every week"
        case .biweekly:
            return "Every 2 weeks"
        case .monthly:
            return "Every month"
        case .quarterly:
            return "Every 3 months"
        case .yearly:
            return "Every year"
        }
    }
}

struct RecurringTransaction: Identifiable, Codable {
    var id: UUID
    var baseTransaction: Transaction
    var frequency: RecurringFrequency
    var startDate: Date
    var endDate: Date?
    var lastProcessedDate: Date?
    
    init(baseTransaction: Transaction, frequency: RecurringFrequency, startDate: Date, endDate: Date? = nil) {
        self.id = UUID()
        self.baseTransaction = baseTransaction
        self.frequency = frequency
        self.startDate = startDate
        self.endDate = endDate
        self.lastProcessedDate = startDate
    }
} 