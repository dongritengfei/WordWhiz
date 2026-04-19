import SwiftUI
import SwiftData

@Observable
@MainActor
final class HistoryViewModel {
    var searchQuery: String = ""
    var records: [OptimizationRecord] = []
    var selectedRecord: OptimizationRecord?

    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        fetchRecords()
    }

    func fetchRecords() {
        guard let modelContext else { return }

        var descriptor = FetchDescriptor<OptimizationRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        if !searchQuery.isEmpty {
            descriptor.predicate = #Predicate<OptimizationRecord> { record in
                record.sourceText.contains(searchQuery) || record.resultText.contains(searchQuery)
            }
        }

        do {
            records = try modelContext.fetch(descriptor)
        } catch {
            records = []
        }
    }

    func deleteRecord(_ record: OptimizationRecord) {
        guard let modelContext else { return }
        modelContext.delete(record)
        try? modelContext.save()
        fetchRecords()
    }

    func clearAllHistory() {
        guard let modelContext else { return }
        for record in records {
            modelContext.delete(record)
        }
        try? modelContext.save()
        records = []
    }

    func search(_ query: String) {
        searchQuery = query
        fetchRecords()
    }
}
