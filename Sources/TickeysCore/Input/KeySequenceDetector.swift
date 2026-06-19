public struct KeySequenceDetector {
    public static let defaultSequences: [[UInt8]] = [
        [12, 0, 6, 18, 19, 20],
        [12, 0, 6, 83, 84, 85]
    ]

    private let sequences: [[UInt8]]
    private let maxLength: Int
    private var recentKeys: [UInt8] = []

    public init(sequences: [[UInt8]] = KeySequenceDetector.defaultSequences) {
        self.sequences = sequences
        self.maxLength = sequences.map(\.count).max() ?? 0
    }

    public mutating func record(keyCode: UInt8) -> Bool {
        recentKeys.append(keyCode)
        if recentKeys.count > maxLength {
            recentKeys.removeFirst(recentKeys.count - maxLength)
        }

        return sequences.contains { sequence in
            recentKeys.suffix(sequence.count).elementsEqual(sequence)
        }
    }

    public mutating func reset() {
        recentKeys.removeAll(keepingCapacity: true)
    }
}
