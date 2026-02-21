//
//  SentryManager.swift
//  NepaliDaateMenuBar
//
//  Manages Sentry initialization, error tracking, breadcrumbs, and structured logging
//

import Foundation
import Sentry

class SentryManager {
    static let shared = SentryManager()
    private var isInitialized = false
    
    private init() {}
    
    // MARK: - Setup
    
    func setup() {
        guard let dsn = Bundle.main.object(forInfoDictionaryKey: "SentryDSN") as? String,
              !dsn.isEmpty,
              dsn != "$(SENTRY_DSN)" else {
            #if DEBUG
            print("⚠️ Sentry: DSN not found or not configured (SENTRY_DSN build setting missing). Skipping initialization.")
            #endif
            return
        }

        #if DEBUG
        print("🔍 Sentry: Loaded DSN: \(dsn)")
        #endif

        SentrySDK.start { options in
            options.dsn = dsn
            
            // Adds IP for users
            // https://docs.sentry.io/platforms/apple/data-management/data-collected/
            options.sendDefaultPii = true
            // options.experimental.enableLogs = true // Removed: not available in Sentry Cocoa 9.5.0
            
            // Performance monitoring
            options.tracesSampleRate = 1.0
            
            // Session tracking for crash-free rate
            options.enableAutoSessionTracking = true
            options.sessionTrackingIntervalMillis = 30_000
            
            // Capture HTTP client errors
            options.enableCaptureFailedRequests = true
            
            // App lifecycle breadcrumbs
            options.enableAutoBreadcrumbTracking = true
            
            // Environment & release
            #if DEBUG
            options.environment = "development"
            options.debug = true
            #else
            options.environment = "production"
            options.debug = false
            #endif
            
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                options.releaseName = "com.stha-ums.NepaliDaateMenuBar@\(version)+\(build)"
            }
            
            // Before-send hook: enrich events with extra context
            options.beforeSend = { event in
                event.tags?["app.locale"] = Locale.current.identifier
                event.tags?["app.language"] = LanguageSettings.shared.language.rawValue
                return event
            }
        }
        
        // Start continuous profiler
        SentrySDK.startProfiler()
        
        isInitialized = true
        setUserContext()
        
        log("Sentry initialized", level: .info)
        
        // Send a test log to verify logs are arriving in Sentry
        SentrySDK.logger.info("Sending a test info log")
        SentrySDK.logger.warn("Sending a test warning log", attributes: [
            "log_type": "test",
        ])
    }
    
    // MARK: - User Context
    
    /// Sets anonymous user context so Sentry can group issues by user.
    private func setUserContext() {
        let user = User()
        // Use a stable anonymous ID based on hardware
        if let hardwareUUID = getHardwareUUID() {
            user.userId = hardwareUUID
        }
        let segment: String = {
            #if DEBUG
            return "debug"
            #else
            return "release"
            #endif
        }()
        user.data = ["segment": segment]
        SentrySDK.setUser(user)
    }
    
    private func getHardwareUUID() -> String? {
        // kIOMasterPortDefault was renamed to kIOMainPortDefault in macOS 12.0. Both evaluate to 0.
        let platformExpert = IOServiceGetMatchingService(
            0,
            IOServiceMatching("IOPlatformExpertDevice")
        )
        guard platformExpert != 0 else { return nil }
        defer { IOObjectRelease(platformExpert) }
        
        guard let serialNumberAsCFString = IORegistryEntryCreateCFProperty(
            platformExpert,
            kIOPlatformUUIDKey as CFString,
            kCFAllocatorDefault,
            0
        ) else { return nil }
        
        return serialNumberAsCFString.takeUnretainedValue() as? String
    }
    
    // MARK: - Structured Logging (Sentry Logs)
    
    /// Log a message to Sentry's structured logging system.
    /// - Parameters:
    ///   - message: The log message
    ///   - level: Sentry log level
    ///   - extra: Additional key-value context attached to the log
    func log(_ message: String, level: SentryLevel = .info, extra: [String: Any]? = nil) {
        guard isInitialized else { return }
        
        // Add as a breadcrumb so it appears in future error reports
        let crumb = Breadcrumb(level: level, category: "app")
        crumb.message = message
        if let extra = extra {
            crumb.data = extra.mapValues { "\($0)" }
        }
        SentrySDK.addBreadcrumb(crumb)
        
        // Send log directly to Sentry Logger if it's available
        let attrs: [String: String] = extra?.mapValues { "\($0)" } ?? [:]
        
        switch level {
        case .debug:
            SentrySDK.logger.debug(message, attributes: attrs)
        case .info:
            SentrySDK.logger.info(message, attributes: attrs)
        case .warning:
            SentrySDK.logger.warn(message, attributes: attrs)
        case .error, .fatal:
            SentrySDK.logger.error(message, attributes: attrs)
        default:
            SentrySDK.logger.info(message, attributes: attrs)
        }
        
        #if DEBUG
        let emoji: String
        switch level {
        case .debug:   emoji = "🔍"
        case .info:    emoji = "ℹ️"
        case .warning: emoji = "⚠️"
        case .error:   emoji = "❌"
        case .fatal:   emoji = "💀"
        default:       emoji = "📝"
        }
        print("\(emoji) Sentry[\(level)]: \(message)")
        if let extra = extra {
            print("   ↳ context: \(extra)")
        }
        #endif
    }
    
    // MARK: - Error Capture
    
    /// Capture a Swift `Error` with optional extra context.
    func captureError(_ error: Error, extra: [String: Any]? = nil) {
        guard isInitialized else { return }
        
        SentrySDK.capture(error: error) { scope in
            if let extra = extra {
                for (key, value) in extra {
                    scope.setExtra(value: value, key: key)
                }
            }
        }
        
        log("Error captured: \(error.localizedDescription)", level: .error, extra: extra)
    }
    
    /// Capture a message with a given severity.
    func captureMessage(_ message: String, level: SentryLevel = .error, extra: [String: Any]? = nil) {
        guard isInitialized else { return }
        
        SentrySDK.capture(message: message) { scope in
            scope.setLevel(level)
            if let extra = extra {
                for (key, value) in extra {
                    scope.setExtra(value: value, key: key)
                }
            }
        }
        
        log("Message captured: \(message)", level: level, extra: extra)
    }
    
    // MARK: - Breadcrumbs
    
    /// Add a navigation breadcrumb (e.g., opening settings, popover, etc.)
    func trackNavigation(from: String? = nil, to: String) {
        guard isInitialized else { return }
        
        let crumb = Breadcrumb(level: .info, category: "navigation")
        crumb.type = "navigation"
        var data: [String: String] = ["to": to]
        if let from = from {
            data["from"] = from
        }
        crumb.data = data
        SentrySDK.addBreadcrumb(crumb)
    }
    
    /// Add a user action breadcrumb (e.g., button tap, menu selection)
    func trackUserAction(_ action: String, extra: [String: String]? = nil) {
        guard isInitialized else { return }
        
        let crumb = Breadcrumb(level: .info, category: "user")
        crumb.type = "user"
        crumb.message = action
        if let extra = extra {
            crumb.data = extra
        }
        SentrySDK.addBreadcrumb(crumb)
    }
    
    // MARK: - Performance (Transactions)
    
    /// Start a performance transaction span. Call `.finish()` on the returned span when done.
    func startTransaction(name: String, operation: String) -> Span? {
        guard isInitialized else { return nil }
        return SentrySDK.startTransaction(name: name, operation: operation)
    }
    
    // MARK: - Debug / Testing
    
    func crash() {
        #if DEBUG
        // 1. Explicitly capture an error message event instead of just a local log
        SentryManager.shared.captureMessage(
            "Sending a test warning log for crash",
            level: .warning,
            extra: ["log_type": "test_crash"]
        )
        
        // 2. Also log locally using Sentry manager
        log("Manual crash triggered", level: .fatal)
        
        // 3. Force Sentry to upload the event immediately before crashing
        SentrySDK.flush(timeout: 2.0)
        
        // 4. Trigger the actual crash
        fatalError("Sentry Manual Crash Triggered")
        #endif
    }
}
