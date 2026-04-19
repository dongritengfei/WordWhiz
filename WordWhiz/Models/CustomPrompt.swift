import Foundation
import SwiftData

@Model
final class CustomPrompt {
    var id: UUID = UUID()
    var name: String = ""
    var promptTemplate: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var sortOrder: Int = 0

    init(name: String, promptTemplate: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.promptTemplate = promptTemplate
        self.createdAt = Date()
        self.updatedAt = Date()
        self.sortOrder = sortOrder
    }

    var preview: String {
        let lines = promptTemplate.components(separatedBy: .newlines)
        return lines.joined(separator: " ")
    }
}
