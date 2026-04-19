import Foundation

enum DiffCalculator {
    enum DiffType {
        case unchanged
        case added
        case removed
    }

    struct DiffSegment: Identifiable {
        let id = UUID()
        let text: String
        let type: DiffType
    }

    /// Line-based diff using a simple LCS-style approach.
    /// Produces segments that show removed, added, and unchanged lines inline.
    static func computeDiff(source: String, result: String) -> [DiffSegment] {
        let sourceLines = source.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let resultLines = result.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        // Build sets for quick lookup
        let sourceSet = Set(sourceLines)
        let resultSet = Set(resultLines)

        var segments: [DiffSegment] = []

        // Track which lines we've already processed
        var processedSource = Set<Int>()
        var processedResult = Set<Int>()

        // Walk through both arrays, matching common lines
        for (sIdx, sLine) in sourceLines.enumerated() {
            if resultSet.contains(sLine) {
                // Find matching line in result that hasn't been processed
                if let rIdx = resultLines.enumerated().first(where: { $0.element == sLine && !processedResult.contains($0.offset) })?.offset {
                    // First, emit any added lines before this match
                    for r in processedResult.count..<rIdx where !processedResult.contains(r) {
                        if !resultLines[r].trimmingCharacters(in: .whitespaces).isEmpty {
                            segments.append(DiffSegment(text: resultLines[r], type: .added))
                            processedResult.insert(r)
                        }
                    }
                    segments.append(DiffSegment(text: sLine, type: .unchanged))
                    processedSource.insert(sIdx)
                    processedResult.insert(rIdx)
                } else {
                    segments.append(DiffSegment(text: sLine, type: .removed))
                    processedSource.insert(sIdx)
                }
            } else {
                segments.append(DiffSegment(text: sLine, type: .removed))
                processedSource.insert(sIdx)
            }
        }

        // Emit remaining added lines
        for (rIdx, rLine) in resultLines.enumerated() {
            if !processedResult.contains(rIdx) && !rLine.trimmingCharacters(in: .whitespaces).isEmpty {
                segments.append(DiffSegment(text: rLine, type: .added))
            }
        }

        return segments
    }
}
