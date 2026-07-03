import AppKit
import MacLockCore
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    @Published private(set) var state: WorkSessionState = .idle

    private var session = WorkSession()
    private var timer: Timer?
    private var window: NSWindow?
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        showWindow()
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
    }

    func startWork() {
        state = session.start(nowSeconds: Date().timeIntervalSinceReferenceDate)
        timer?.invalidate()

        let timer = Timer(timeInterval: 1, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer

        closeWindow()
    }

    func dayEnd() {
        timer?.invalidate()
        timer = nil
        state = session.dayEnd()
    }

    private func configureStatusItem() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "lock.fill", accessibilityDescription: "MacLock")
            button.imagePosition = .imageOnly
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open MacLock", action: #selector(openFromMenu), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Close Window", action: #selector(closeFromMenu), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit MacLock", action: #selector(quitFromMenu), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 280),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "MacLock"
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(rootView: MacLockView(app: self))
        window.center()
        return window
    }

    private func showWindow() {
        if window == nil {
            window = makeWindow()
        }

        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func closeWindow() {
        window?.close()
    }

    @objc private func timerFired() {
        state = session.tick(nowSeconds: Date().timeIntervalSinceReferenceDate)
        if case .breakDue = state {
            timer?.invalidate()
            timer = nil
            showWindow()
        }
    }

    @objc private func openFromMenu() {
        showWindow()
    }

    @objc private func closeFromMenu() {
        closeWindow()
    }

    @objc private func quitFromMenu() {
        NSApp.terminate(nil)
    }
}

struct MacLockView: View {
    @ObservedObject var app: AppDelegate

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(circleColor, lineWidth: 8)
                    .background(Circle().fill(Color(nsColor: .windowBackgroundColor)))

                VStack(spacing: 4) {
                    Text(primaryText)
                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    Text(secondaryText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, height: 120)

            Text(statusText)
                .font(.system(size: 14, weight: .medium))
                .multilineTextAlignment(.center)
                .frame(height: 36)

            HStack(spacing: 12) {
                Button("Start Work") {
                    app.startWork()
                }
                .keyboardShortcut(.defaultAction)

                Button("Day End") {
                    app.dayEnd()
                }
            }
        }
        .padding(24)
        .frame(width: 300, height: 280)
    }

    private var primaryText: String {
        switch app.state {
        case .idle:
            return "45"
        case .running(let remainingSeconds):
            return formatRemaining(remainingSeconds)
        case .breakDue:
            return "Rest"
        case .dayEnded:
            return "Done"
        }
    }

    private var secondaryText: String {
        switch app.state {
        case .idle:
            return "min"
        case .running:
            return "left"
        case .breakDue:
            return "break"
        case .dayEnded:
            return "today"
        }
    }

    private var statusText: String {
        switch app.state {
        case .idle:
            return "Ready to begin."
        case .running:
            return "Work timer is running."
        case .breakDue:
            return "Time to rest. Start Work when ready."
        case .dayEnded:
            return "Day ended. Start Work to restart."
        }
    }

    private var circleColor: Color {
        switch app.state {
        case .idle:
            return .secondary
        case .running:
            return .blue
        case .breakDue:
            return .green
        case .dayEnded:
            return .orange
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
