import MacLockCore

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

var session = WorkSession(durationSeconds: 2)

expect(session.state == .idle, "new session should be idle")
expect(session.start(nowSeconds: 100) == .running(remainingSeconds: 2), "start should begin full timer")
expect(session.tick(nowSeconds: 101) == .running(remainingSeconds: 1), "first tick should reduce remaining time")
expect(session.start(nowSeconds: 102) == .running(remainingSeconds: 2), "start should reset a running timer")
expect(session.tick(nowSeconds: 103) == .running(remainingSeconds: 1), "reset timer should use the new deadline")
expect(session.tick(nowSeconds: 105) == .breakDue, "late tick should move to break due after the reset deadline")
expect(session.dayEnd() == .dayEnded, "day end should stop the loop")
expect(session.tick(nowSeconds: 104) == .dayEnded, "day ended should ignore ticks")
expect(session.start(nowSeconds: 200) == .running(remainingSeconds: 2), "start should restart after day end")
expect(formatRemaining(65) == "01:05", "remaining time should be mm:ss")

print("MacLockCheck passed")
