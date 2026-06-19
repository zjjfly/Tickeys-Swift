public struct RepeatedKeyThrottler {
    private let windowMilliseconds: UInt64
    private var lastKeyCode: UInt8?
    private var lastTimeMilliseconds: UInt64?

    public init(windowMilliseconds: UInt64 = 120) {
        self.windowMilliseconds = windowMilliseconds
    }

    public mutating func shouldSuppress(keyCode: UInt8, atMilliseconds now: UInt64) -> Bool {
        defer {
            lastKeyCode = keyCode
            lastTimeMilliseconds = now
        }

        guard let lastKeyCode, let lastTimeMilliseconds else {
            return false
        }

        return keyCode == lastKeyCode && now >= lastTimeMilliseconds && now - lastTimeMilliseconds < windowMilliseconds
    }
}
