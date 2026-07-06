import AppKit
import MacLockCore
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    @Published private(set) var state: WorkSessionState = .idle

    private var session = WorkSession()
    private var timer: Timer?
    private var window: NSPanel?
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

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
        updateStatusIcon()
        timer?.invalidate()

        let timer = Timer(timeInterval: 1, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func dayEnd() {
        timer?.invalidate()
        timer = nil
        state = session.dayEnd()
        updateStatusIcon()
    }

    private func configureStatusItem() {
        if let button = statusItem.button {
            button.imagePosition = .imageOnly
            button.imageScaling = .scaleProportionallyDown
            button.toolTip = "MacLock"
        }
        updateStatusIcon()

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open MacLock", action: #selector(openFromMenu), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Close Window", action: #selector(closeFromMenu), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit MacLock", action: #selector(quitFromMenu), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    private func makeWindow() -> NSPanel {
        let window = MacLockPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 280),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "MacLock"
        window.isReleasedWhenClosed = false
        keepWindowOnTop(window)
        window.contentViewController = NSHostingController(rootView: MacLockView(app: self))
        window.center()
        return window
    }

    private func keepWindowOnTop(_ window: NSPanel) {
        window.isFloatingPanel = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.hidesOnDeactivate = false
    }

    private func showWindow() {
        if window == nil {
            window = makeWindow()
        }

        guard let window else { return }

        keepWindowOnTop(window)
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func closeWindow() {
        window?.close()
    }

    @objc private func timerFired() {
        state = session.tick(nowSeconds: Date().timeIntervalSinceReferenceDate)
        updateStatusIcon()
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

    private func updateStatusIcon() {
        let progress = progressFraction(for: state, durationSeconds: session.durationSeconds)
        statusItem.button?.image = makeStatusIcon(progress: progress, trackAlpha: statusIconTrackAlpha)
    }

    private var statusIconTrackAlpha: CGFloat {
        switch state {
        case .idle:
            return 0.35
        case .running:
            return 0.22
        case .breakDue:
            return 0.16
        case .dayEnded:
            return 0.18
        }
    }

    private func makeStatusIcon(progress: Double, trackAlpha: CGFloat) -> NSImage {
        let imageSize = NSSize(width: 18, height: 18)
        let lineWidth: CGFloat = 2.25
        let rect = NSRect(
            x: 2.125,
            y: 2.125,
            width: imageSize.width - 4.25,
            height: imageSize.height - 4.25
        )
        let clampedProgress = min(1, max(0, progress))
        let image = NSImage(size: imageSize)

        image.lockFocus()

        let trackPath = NSBezierPath(ovalIn: rect)
        trackPath.lineWidth = lineWidth
        trackPath.lineCapStyle = .round
        NSColor.black.withAlphaComponent(trackAlpha).setStroke()
        trackPath.stroke()

        if clampedProgress > 0 {
            let progressPath = NSBezierPath()
            if clampedProgress >= 0.999 {
                progressPath.appendOval(in: rect)
            } else {
                let center = NSPoint(x: imageSize.width / 2, y: imageSize.height / 2)
                progressPath.appendArc(
                    withCenter: center,
                    radius: rect.width / 2,
                    startAngle: 90,
                    endAngle: 90 - 360 * clampedProgress,
                    clockwise: true
                )
            }

            progressPath.lineWidth = lineWidth
            progressPath.lineCapStyle = .round
            NSColor.black.setStroke()
            progressPath.stroke()
        }

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}

private final class MacLockPanel: NSPanel {
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
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
