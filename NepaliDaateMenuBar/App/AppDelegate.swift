//
//  AppDelegate.swift
//  NepaliDaateMenuBar
//
//  Application delegate handling menu bar item
//

import AppKit
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    var popover: NSPopover?
    var onboardingWindow: NSWindow?
    var settingsWindow: NSWindow?
    var aboutWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    
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
            
            // Setup menu bar
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
                }
            }
        }
    }
    
    private func setupMenu() {
        // Menu is created dynamically on right-click
    }
    
    private func createMenu() -> NSMenu {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "About", action: #selector(openAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        return menu
    }
    
    @objc func openAbout() {
        popover?.performClose(nil)
        
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
        
        // Reset to normal level after window is shown
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            window.level = .normal
        }
    }
    
    @objc func openSettings() {
        // Close popover if open
        popover?.performClose(nil)
        
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
        
        // Reset to normal level after window is shown
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            window.level = .normal
        }
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
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
            
            // Listen for onboarding completion
            OnboardingManager.shared.$hasCompletedOnboarding
                .sink { [weak self] completed in
                    if completed {
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
            .sink { [weak self] _ in
                self?.updateDateDisplay()
            }
            .store(in: &cancellables)
        
        DateFormatSettings.shared.$customPattern
            .sink { [weak self] _ in
                self?.updateDateDisplay()
            }
            .store(in: &cancellables)
        
        LanguageSettings.shared.$language
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
    }
}

