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

    /// Line-based diff using standard LCS dynamic programming.
    /// Produces segments that show removed, added, and unchanged lines inline.
    static func computeDiff(source: String, result: String) -> [DiffSegment] {
        let sourceLines = source.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let resultLines = result.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        let n = sourceLines.count
        let m = resultLines.count

        // dp[i][j] = length of LCS of sourceLines[i...] and resultLines[j...]
        var dp = [[Int]](repeating: [Int](repeating: 0, count: m + 1), count: n + 1)
        if n > 0 && m > 0 {
            for i in (0..<n).reversed() {
                for j in (0..<m).reversed() {
                    if sourceLines[i] == resultLines[j] {
                        dp[i][j] = dp[i + 1][j + 1] + 1
                    } else {
                        dp[i][j] = max(dp[i + 1][j], dp[i][j + 1])
                    }
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
