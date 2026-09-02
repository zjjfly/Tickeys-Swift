public struct KeySequenceDetector {
    public static let defaultSequences: [[UInt8]] = [
        [12, 0, 6, 18, 19, 20],
        [12, 0, 6, 83, 84, 85]
    ]

    private let sequences: [[UInt8]]
    private let maxLength: Int
    private var recentKeys: [UInt8]
    private var nextKeyIndex = 0

    public init(sequences: [[UInt8]] = KeySequenceDetector.defaultSequences) {
        self.sequences = sequences
        self.maxLength = sequences.map(\.count).max() ?? 0
        self.recentKeys = Array(repeating: 0, count: maxLength)
    }

    public mutating func record(keyCode: UInt8) -> Bool {
        guard maxLength > 0 else {
            return false
        }

        recentKeys[nextKeyIndex] = keyCode
        nextKeyIndex = (nextKeyIndex + 1) % maxLength

        return sequences.contains { sequence in
            guard sequence.count <= maxLength else {
                return false
            }

            let startIndex = (nextKeyIndex - sequence.count + maxLength) % maxLength
            return sequence.indices.allSatisfy { offset in
                recentKeys[(startIndex + offset) % maxLength] == sequence[offset]
            }
        }
    }

    public mutating func reset() {
        recentKeys = Array(repeating: 0, count: maxLength)
        nextKeyIndex = 0
    }
}
