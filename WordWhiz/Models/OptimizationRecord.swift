import Foundation
import SwiftData

@Model
final class OptimizationRecord {
    var id: UUID = UUID()
    var sourceText: String = ""
    var resultText: String = ""
    var promptName: String?
    var createdAt: Date = Date()
    var characterCount: Int = 0

    init(
        sourceText: String,
        resultText: String,
        promptName: String? = nil,
        characterCount: Int = 0
    ) {
        self.id = UUID()
        self.sourceText = sourceText
        self.resultText = resultText
        self.promptName = promptName
        self.createdAt = Date()
        self.characterCount = characterCount
    }
}

// MARK: - Date Formatting

extension Date {
    func formattedString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: self)
    }
}
