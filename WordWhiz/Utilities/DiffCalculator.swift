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

    /// Max DP cells for the LCS table. Above this the middle section falls back
    /// to a plain replace, bounding memory (~2 MB) and main-thread time.
    private static let maxDiffCells = 250_000

    /// Line-based diff using standard LCS dynamic programming.
    /// Produces segments that show removed, added, and unchanged lines inline.
    static func computeDiff(source: String, result: String) -> [DiffSegment] {
        let sourceLines = source.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let resultLines = result.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        var segments: [DiffSegment] = []

        // Common prefix — identical lines need no DP
        var prefixLen = 0
        while prefixLen < sourceLines.count && prefixLen < resultLines.count
            && sourceLines[prefixLen] == resultLines[prefixLen] {
            segments.append(DiffSegment(text: sourceLines[prefixLen], type: .unchanged))
            prefixLen += 1
        }

        // Common suffix — counted first, appended after the middle section
        var suffixLen = 0
        while suffixLen < sourceLines.count - prefixLen && suffixLen < resultLines.count - prefixLen
            && sourceLines[sourceLines.count - 1 - suffixLen] == resultLines[resultLines.count - 1 - suffixLen] {
            suffixLen += 1
        }

        let middleSource = Array(sourceLines[prefixLen ..< sourceLines.count - suffixLen])
        let middleResult = Array(resultLines[prefixLen ..< resultLines.count - suffixLen])
        segments.append(contentsOf: middleDiff(middleSource, middleResult))

        for idx in (sourceLines.count - suffixLen) ..< sourceLines.count {
            segments.append(DiffSegment(text: sourceLines[idx], type: .unchanged))
        }

        return segments
    }

    /// LCS diff of the differing middle section only.
    private static func middleDiff(_ sourceLines: [String], _ resultLines: [String]) -> [DiffSegment] {
        let n = sourceLines.count
        let m = resultLines.count

        // Degenerate or oversized input: show a plain replace instead of LCS
        if n == 0 { return resultLines.map { DiffSegment(text: $0, type: .added) } }
        if m == 0 { return sourceLines.map { DiffSegment(text: $0, type: .removed) } }
        if n * m > maxDiffCells {
            return sourceLines.map { DiffSegment(text: $0, type: .removed) }
                + resultLines.map { DiffSegment(text: $0, type: .added) }
        }

        // dp[i][j] = length of LCS of sourceLines[i...] and resultLines[j...]
        var dp = [[Int]](repeating: [Int](repeating: 0, count: m + 1), count: n + 1)
        for i in (0..<n).reversed() {
            for j in (0..<m).reversed() {
                if sourceLines[i] == resultLines[j] {
                    dp[i][j] = dp[i + 1][j + 1] + 1
                } else {
                    dp[i][j] = max(dp[i + 1][j], dp[i][j + 1])
                }
            }
        }

        var segments: [DiffSegment] = []
        var i = 0
        var j = 0
        while i < n && j < m {
            if sourceLines[i] == resultLines[j] {
                segments.append(DiffSegment(text: sourceLines[i], type: .unchanged))
                i += 1
                j += 1
            } else if dp[i + 1][j] >= dp[i][j + 1] {
                segments.append(DiffSegment(text: sourceLines[i], type: .removed))
                i += 1
            } else {
                segments.append(DiffSegment(text: resultLines[j], type: .added))
                j += 1
            }
        }
        while i < n {
            segments.append(DiffSegment(text: sourceLines[i], type: .removed))
            i += 1
        }
        while j < m {
            segments.append(DiffSegment(text: resultLines[j], type: .added))
            j += 1
        }

        return segments
    }
}
