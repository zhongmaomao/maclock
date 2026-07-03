public enum WorkSessionState: Equatable, Sendable {
    case idle
    case running(remainingSeconds: Int)
    case breakDue
    case dayEnded
}

public struct WorkSession: Equatable, Sendable {
    public let durationSeconds: Int
    public private(set) var state: WorkSessionState
    private var deadlineSeconds: Double?

    public init(durationSeconds: Int = 45 * 60) {
        precondition(durationSeconds > 0, "durationSeconds must be positive")
        self.durationSeconds = durationSeconds
        state = .idle
        deadlineSeconds = nil
    }

    @discardableResult
    public mutating func start(nowSeconds: Double) -> WorkSessionState {
        deadlineSeconds = nowSeconds + Double(durationSeconds)
        state = .running(remainingSeconds: durationSeconds)
        return state
    }

    @discardableResult
    public mutating func tick(nowSeconds: Double) -> WorkSessionState {
        guard case .running = state, let deadlineSeconds else {
            return state
        }

        let remainingSeconds = deadlineSeconds - nowSeconds
        state = remainingSeconds > 0
            ? .running(remainingSeconds: Int(remainingSeconds.rounded(.up)))
            : .breakDue
        return state
    }

    @discardableResult
    public mutating func dayEnd() -> WorkSessionState {
        deadlineSeconds = nil
        state = .dayEnded
        return state
    }
}

public func formatRemaining(_ seconds: Int) -> String {
    let clamped = max(0, seconds)
    let minutes = clamped / 60
    let remainder = clamped % 60
    let minuteText = minutes < 10 ? "0\(minutes)" : "\(minutes)"
    let secondText = remainder < 10 ? "0\(remainder)" : "\(remainder)"
    return "\(minuteText):\(secondText)"
}
