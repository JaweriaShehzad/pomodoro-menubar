import AppKit

// Menu bar Pomodoro: click ▶ to start a 45-min focus (green), then a 15-min break (red) with beeping.
let FOCUS: TimeInterval = 45 * 60
let BREAK: TimeInterval = 15 * 60
let DAILY_GOAL = 8

// Completed focus sessions today, saved so it survives restarts.
// A "study day" runs 5 AM → 5 AM, so late-night sessions still count toward the same day.
struct Tally {
    static let d = UserDefaults.standard
    static var today: String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date().addingTimeInterval(-5 * 3600))
    }
    static var count: Int {
        get { d.string(forKey: "tallyDate") == today ? d.integer(forKey: "tallyCount") : 0 }
        set { d.set(today, forKey: "tallyDate"); d.set(newValue, forKey: "tallyCount") }
    }
}

enum Phase { case idle, focus, rest }

final class App: NSObject, NSApplicationDelegate {
    var item: NSStatusItem!
    var phase: Phase = .idle
    var endsAt = Date()
    var tick: Timer?
    var beepTimer: Timer?
    var beepsLeft = 0
    let green = NSColor(calibratedRed: 0.09, green: 0.70, blue: 0.29, alpha: 1)
    let red = NSColor(calibratedRed: 0.90, green: 0.18, blue: 0.18, alpha: 1)

    func applicationDidFinishLaunching(_ n: Notification) {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.target = self
        item.button?.action = #selector(clicked)
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        restore()
        render()
        tick = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in self?.update() }
        RunLoop.main.add(tick!, forMode: .common)
    }

    // Idle: a click starts the session. Running (or right-click): show menu.
    @objc func clicked() {
        let right = NSApp.currentEvent?.type == .rightMouseUp
        if phase == .idle && !right { startFocus(); return }
        stopBeeping()
        let m = NSMenu()
        let mins = Tally.count * Int(FOCUS / 60)
        m.addItem(withTitle: "Today: \(Tally.count)/\(DAILY_GOAL) sessions · \(mins / 60)h \(mins % 60)m studied", action: nil, keyEquivalent: "")
        m.addItem(.separator())
        if phase == .idle { m.addItem(withTitle: "▶ Start 45-min focus", action: #selector(startFocus), keyEquivalent: "").target = self }
        if phase == .focus { m.addItem(withTitle: "Skip to break", action: #selector(startBreak), keyEquivalent: "").target = self }
        if phase == .rest { m.addItem(withTitle: "▶ Start next focus now", action: #selector(startFocus), keyEquivalent: "").target = self }
        if phase != .idle { m.addItem(withTitle: "■ Stop", action: #selector(stop), keyEquivalent: "").target = self }
        m.addItem(.separator())
        m.addItem(withTitle: "+1 session (add manually)", action: #selector(addOne), keyEquivalent: "").target = self
        m.addItem(withTitle: "−1 session", action: #selector(removeOne), keyEquivalent: "").target = self
        m.addItem(withTitle: "Reset today's count", action: #selector(resetCount), keyEquivalent: "").target = self
        m.addItem(withTitle: "Quit Pomodoro", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.menu = m
        item.button?.performClick(nil)
        item.menu = nil
    }

    @objc func startFocus() { stopBeeping(); phase = .focus; endsAt = Date().addingTimeInterval(FOCUS); save(); render() }
    @objc func startBreak() { phase = .rest; endsAt = Date().addingTimeInterval(BREAK); save(); render() }
    @objc func stop() { stopBeeping(); phase = .idle; save(); render() }
    @objc func resetCount() { Tally.count = 0; render() }
    @objc func addOne() { Tally.count += 1; render() }
    @objc func removeOne() { Tally.count = max(0, Tally.count - 1); render() }

    // Persist the running timer so quitting/restarting the app resumes it.
    func save() {
        let d = UserDefaults.standard
        d.set(phase == .focus ? "focus" : phase == .rest ? "rest" : "idle", forKey: "phase")
        d.set(endsAt.timeIntervalSince1970, forKey: "endsAt")
    }
    func restore() {
        let d = UserDefaults.standard
        endsAt = Date(timeIntervalSince1970: d.double(forKey: "endsAt"))
        switch d.string(forKey: "phase") {
        case "focus": phase = .focus
        case "rest": phase = endsAt > Date() ? .rest : .idle
        default: phase = .idle
        }
    }

    func update() {
        guard phase != .idle else { return }
        if Date() >= endsAt {
            if phase == .focus {
                Tally.count += 1
                startBreak()
                notify("Session \(Tally.count)/\(DAILY_GOAL) done 🔴", "15-min break starts now. Click the timer to silence the beeping.")
                startBeeping(times: 20)
            } else {
                phase = .idle
                save()
                notify("Break over 🟢", "Click ▶ in the menu bar to start the next session.")
                startBeeping(times: 6)
            }
        }
        render()
    }

    func render() {
        guard let b = item.button else { return }
        let font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
        let title = NSMutableAttributedString()
        switch phase {
        case .idle:
            title.append(NSAttributedString(string: "▶ 45:00", attributes: [.font: font]))
        case .focus, .rest:
            let s = max(0, Int(ceil(endsAt.timeIntervalSinceNow)))
            let text = String(format: "%@ %02d:%02d", phase == .focus ? "●" : "☕︎", s / 60, s % 60)
            title.append(NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: phase == .focus ? green : red]))
        }
        // Session tally appears once the first session of the day is finished.
        if Tally.count > 0 {
            title.append(NSAttributedString(string: "  \(Tally.count)/\(DAILY_GOAL)", attributes: [.font: font]))
        }
        b.attributedTitle = title
    }

    // Beeps every 1.5 s until it has beeped `times` times or the user clicks the timer.
    func startBeeping(times: Int) {
        stopBeeping()
        beepsLeft = times
        beepTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            (NSSound(named: "Glass") ?? NSSound(named: "Ping"))?.play()
            self.beepsLeft -= 1
            if self.beepsLeft <= 0 { self.stopBeeping() }
        }
        beepTimer?.fire()
    }
    func stopBeeping() { beepTimer?.invalidate(); beepTimer = nil }

    func notify(_ title: String, _ body: String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        p.arguments = ["-e", "display notification \"\(body)\" with title \"\(title)\""]
        try? p.run()
    }
}

let app = NSApplication.shared
let delegate = App()
app.delegate = delegate
app.setActivationPolicy(.accessory)   // menu bar only, no Dock icon
app.run()
