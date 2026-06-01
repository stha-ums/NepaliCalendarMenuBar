//
//  AppDelegate.swift
//  NepaliDaateMenuBar
//
//  Application delegate handling menu bar item
//

import AppKit
import SwiftUI
import Combine
import Sentry

class AppDelegate: NSObject, NSApplicationDelegate {
    static private(set) var shared: AppDelegate!
    
    var statusBarItem: NSStatusItem?
    var popover: NSPopover?
    var onboardingWindow: NSWindow?
    var settingsWindow: NSWindow?
    var aboutWindow: NSWindow?
    var dateConverterWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        AppDelegate.shared = self
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        #if DEBUG
        // Development only: Reset settings on launch
        // resetAllSettings()
        #endif
        
        // Ensure we're on the main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.applicationDidFinishLaunching(notification)
            }
            return
        }
        
        // Wait a brief moment for the app's scene system to fully initialize
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            // Check if first launch
            if !OnboardingManager.shared.hasCompletedOnboarding {
                self.showOnboarding()
                return
            }
            
            // Hide dock icon
            NSApp.setActivationPolicy(.accessory)
            
            // Initialize Sentry (before other services so it captures their errors)
            SentryManager.shared.setup()
            
            // Initialize Telemetry
            TelemetryManager.shared.setup()
            
            SentryManager.shared.log("App launched — menu bar mode", level: .info)
            
            // Setup menu bar
            SentryManager.shared.trackNavigation(to: "menu_bar")
            self.setupMenuBar()
        }
    }
    
    // MARK: - Development
    
    #if DEBUG
    private func resetAllSettings() {
        guard let domain = Bundle.main.bundleIdentifier else { return }
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        OnboardingManager.shared.resetOnboarding()
    }
    #endif
    
    @objc func togglePopover(_ sender: AnyObject?) {
        guard let button = statusBarItem?.button else { return }
        
        // Get the current event to detect right-click
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            // Right-click: show menu
            statusBarItem?.menu = createMenu()
            button.performClick(nil)
            statusBarItem?.menu = nil
        } else {
            // Left-click: show popover
            if let popover = popover {
                if popover.isShown {
                    popover.performClose(sender)
                } else {
                    // Activate app to ensure popover can detect clicks outside
                    NSApp.activate(ignoringOtherApps: true)
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                    TelemetryManager.shared.track("popover.opened")
                    SentryManager.shared.trackNavigation(to: "popover")
                }
            }
        }
    }
    
    private func setupMenu() {
        // Menu is created dynamically on right-click
    }
    
    private func createMenu() -> NSMenu {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Date Converter", action: #selector(openDateConverter), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "About", action: #selector(openAbout), keyEquivalent: ""))
        
        #if DEBUG
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Trigger Crash", action: #selector(triggerCrash), keyEquivalent: ""))
        #endif
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        return menu
    }
    
    @objc func openAbout() {
        // Ensure we're on the main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.openAbout()
            }
            return
        }
        
        // Activate app first to ensure window appears on top
        NSApp.activate(ignoringOtherApps: true)
        
        // If about window already exists, bring it to front
        if let existingWindow = aboutWindow, existingWindow.isVisible {
            existingWindow.level = .floating
            existingWindow.orderFrontRegardless()
            existingWindow.makeKeyAndOrderFront(nil)
            // Reset level after a brief moment
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                existingWindow.level = .normal
            }
            popover?.performClose(nil)
            SentryManager.shared.trackUserAction("reopen_about_window")
            return
        }
        
        let aboutView = AboutView()
        let hostingController = NSHostingController(rootView: aboutView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "About"
        window.styleMask = [.titled, .closable, .resizable]
        window.titlebarAppearsTransparent = false
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: Constants.Window.aboutWidth, height: Constants.Window.aboutHeight))
        window.minSize = NSSize(width: 400, height: 500)
        
        // Associate window with the app
        window.collectionBehavior = [.managed, .participatesInCycle]
        
        // Center window on screen
        window.center()
        
        // Store window reference
        aboutWindow = window
        
        // Set delegate to handle window closing
        window.delegate = self
        
        // Temporarily set floating level to ensure it appears on top
        window.level = .floating
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        
        TelemetryManager.shared.track("window.about.opened")
        SentryManager.shared.trackNavigation(to: "about_window")
        
        // Reset to normal level after window is shown
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            window.level = .normal
        }
        
        // Close popover
        popover?.performClose(nil)
    }
    
    @objc func openSettings() {
        // Ensure we're on the main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.openSettings()
            }
            return
        }
        
        // Activate app first to ensure window appears on top
        NSApp.activate(ignoringOtherApps: true)
        
        // If settings window already exists, bring it to front
        if let existingWindow = settingsWindow, existingWindow.isVisible {
            existingWindow.level = .floating
            existingWindow.orderFrontRegardless()
            existingWindow.makeKeyAndOrderFront(nil)
            // Reset level after a brief moment
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                existingWindow.level = .normal
            }
            popover?.performClose(nil)
            SentryManager.shared.trackUserAction("reopen_settings_window")
            return
        }
        
        // Create a fresh window
        let settingsView = SettingsWindow()
        let hostingController = NSHostingController(rootView: settingsView)
            
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Settings"
        window.styleMask = [.titled, .closable]
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .visible
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: Constants.Window.settingsWidth, height: Constants.Window.settingsHeight))
        
        // Associate window with the app
        window.collectionBehavior = [.managed, .participatesInCycle]
        
        // Hide minimize and zoom buttons
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        
        // Center window on screen
        window.center()
        
        // Store window reference
        settingsWindow = window
        
        // Set delegate to handle window closing
        window.delegate = self
        
        // Temporarily set floating level to ensure it appears on top
        window.level = .floating
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        
        TelemetryManager.shared.track("window.settings.opened")
        SentryManager.shared.trackNavigation(to: "settings_window")
        
        // Reset to normal level after window is shown
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            window.level = .normal
        }
        
        // Close popover
        popover?.performClose(nil)
    }
    
    @objc func openDateConverter() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in self?.openDateConverter() }
            return
        }

        NSApp.activate(ignoringOtherApps: true)

        if let existingWindow = dateConverterWindow, existingWindow.isVisible {
            existingWindow.level = .floating
            existingWindow.orderFrontRegardless()
            existingWindow.makeKeyAndOrderFront(nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                existingWindow.level = .normal
            }
            popover?.performClose(nil)
            return
        }

        let hostingController = NSHostingController(rootView: DateConverterView())
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Date Converter"
        window.styleMask = [.titled, .closable]
        window.titlebarAppearsTransparent = false
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: Constants.Window.dateConverterWidth, height: Constants.Window.dateConverterHeight))
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.collectionBehavior = [.managed, .participatesInCycle]
        window.center()
        dateConverterWindow = window
        window.delegate = self
        window.level = .floating
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            window.level = .normal
        }
        TelemetryManager.shared.track("window.date_converter.opened")
        SentryManager.shared.trackNavigation(to: "date_converter_window")
        popover?.performClose(nil)
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc func triggerCrash() {
        SentryManager.shared.trackUserAction("trigger_crash")
        SentryManager.shared.crash()
    }
    
    // MARK: - Onboarding
    
    func showOnboarding() {
        // Ensure we're on the main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.showOnboarding()
            }
            return
        }
        
        // Show dock icon during onboarding
        NSApp.setActivationPolicy(.regular)
        
        // Wait a moment for the app to fully initialize
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            let onboardingView = OnboardingView()
            let hostingController = NSHostingController(rootView: onboardingView)
            
            let window = NSWindow(contentViewController: hostingController)
            window.title = "Welcome"
            window.styleMask = [.titled, .fullSizeContentView]  // Removed .closable
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isReleasedWhenClosed = false
            window.isMovableByWindowBackground = true
            window.level = .floating
            
            // Associate window with the app
            window.collectionBehavior = [.managed, .participatesInCycle]
            
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
            
            self.centerWindow(window, width: Constants.Window.onboardingWidth, height: Constants.Window.onboardingHeight)
            
            self.onboardingWindow = window
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            
            SentryManager.shared.trackNavigation(to: "onboarding")
            SentryManager.shared.log("Onboarding started", level: .info)
            
            // Listen for onboarding completion
            OnboardingManager.shared.$hasCompletedOnboarding
                .sink { [weak self] completed in
                    if completed {
                        SentryManager.shared.log("Onboarding completed", level: .info)
                        self?.onboardingWindow?.close()
                        self?.onboardingWindow = nil
                        
                        // Hide dock icon and setup menu bar
                        NSApp.setActivationPolicy(.accessory)
                        
                        // Setup menu bar
                        self?.setupMenuBar()
                        
                        // Automatically open the popover after a brief delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self?.showPopover()
                        }
                    }
                }
                .store(in: &self.cancellables)
        }
    }
    
    private func showPopover() {
        guard let button = statusBarItem?.button else { return }
        
        if let popover = popover, !popover.isShown {
            // Activate app to ensure popover can detect clicks outside
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
    
    private func setupMenuBar() {
        // Create status bar item
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem?.button {
            button.action = #selector(togglePopover)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            updateDateDisplay()
        }
        
        // Create right-click menu
        setupMenu()
        
        // Create popover
        popover = NSPopover()
        popover?.contentSize = NSSize(width: Constants.Window.popoverWidth, height: Constants.Window.popoverHeight)
        popover?.behavior = .transient
        popover?.animates = true
        popover?.contentViewController = NSHostingController(rootView: MenuBarPopoverView())
        popover?.delegate = self
        
        // Update date every minute
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.updateDateDisplay()
        }
        
        // Listen for format changes
        DateFormatSettings.shared.$formatType
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateDateDisplay()
            }
            .store(in: &cancellables)
        
        DateFormatSettings.shared.$customPattern
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateDateDisplay()
            }
            .store(in: &cancellables)
        
        DateFormatSettings.shared.$showTithi
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateDateDisplay()
            }
            .store(in: &cancellables)
        
        LanguageSettings.shared.$language
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateDateDisplay()
            }
            .store(in: &cancellables)
        
        // Also update when day changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateDateDisplay),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc func updateDateDisplay() {
        guard let button = statusBarItem?.button,
              let nepaliDate = NepaliDateConverter.getCurrentNepaliDate() else {
            statusBarItem?.button?.title = "Nepali Date"
            SentryManager.shared.log("Date display update failed — could not get Nepali date", level: .warning)
            return
        }
        
        button.title = DateFormatSettings.shared.formatForMenuBar(nepaliDate)
        button.toolTip = nepaliDate.formatted(pattern: "MMMM DD, YYYY") + " BS"
    }
    
    // MARK: - Helpers
    
    private func centerWindow(_ window: NSWindow, width: CGFloat, height: CGFloat) {
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - width / 2
            let y = screenFrame.midY - height / 2
            window.setFrame(NSRect(x: x, y: y, width: width, height: height), display: false)
        } else {
            window.center()
        }
    }
}

// MARK: - NSWindowDelegate

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        
        // Clear window references when they close
        if window == settingsWindow {
            settingsWindow = nil
        } else if window == aboutWindow {
            aboutWindow = nil
        } else if window == dateConverterWindow {
            dateConverterWindow = nil
        }
    }
}

// MARK: - NSPopoverDelegate

extension AppDelegate: NSPopoverDelegate {
    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        return true
    }
    
    func popoverDidClose(_ notification: Notification) {
        // Popover closed
        TelemetryManager.shared.track("popover.closed")
        SentryManager.shared.trackUserAction("popover_closed")
        NotificationCenter.default.post(name: .popoverDidClose, object: nil)
    }
}

