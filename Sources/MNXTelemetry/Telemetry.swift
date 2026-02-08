//
//  Telemetry.swift
//  MNXTelemetry
//
//  SPDX-License-Identifier: Apache-2.0
//  See the LICENSE file in the project root for license information.
//
//  Created by Nikita Moshyn on 28/09/2025.
//  Copyright © 2025 Nikita Moshyn. All rights reserved.
//

import Foundation

public final class Telemetry {
    nonisolated(unsafe) public static let shared = Telemetry()
    private init() {}
    
    private var analyticsProviders: [AnalyticsProvider] = []
    private var crashProvider: CrashProvider?
    private var crashProviderStarted = false
    private var optedOut = false
    private var rawEventHandler: TelemetryRawEventHandler?
    private var prettyEventHandler: TelemetryPrettyEventHandler?
    private var prettyEventFormatter: TelemetryPrettyEventFormatter = TelemetryPrettyFormatter.default
    
    private var globalRemoteInDebug = true
    private var globalDebugMode: Bool = {
        #if DEBUG
        true
        #else
        false
        #endif
    }()
    
    // MARK: - Registration
    
    public func register(provider: AnalyticsProvider) {
        analyticsProviders.append(provider)
        applyDebugModeIfSupported(to: provider)
        emitDebugEvent("register_provider", info: [
            "provider": providerName(for: provider),
            "kind": "analytics"
        ])
    }

    public func register(crashProvider: CrashProvider) {
        self.crashProvider = crashProvider
        applyDebugModeIfSupported(to: crashProvider)
        ensureCrashProviderStartedIfNeeded()
        emitDebugEvent("register_provider", info: [
            "provider": providerName(for: crashProvider),
            "kind": "crash",
            "remote_enabled": shouldSendRemote(for: crashProvider)
        ])
    }
    
    // MARK: - Public API

    public func setUser(id: String?, properties: [String: Any] = [:]) {
        guard !optedOut else {
            emitDebugEvent("set_user_skipped", info: ["reason": "opt_out"])
            return
        }
        
        for provider in analyticsProviders {
            let providerName = providerName(for: provider)
            let remoteEnabled = shouldSendRemote(for: provider)
            emitDebugEvent("set_user", info: [
                "provider": providerName,
                "id": id ?? "nil",
                "properties": properties,
                "remote_enabled": remoteEnabled
            ])
            guard remoteEnabled else { continue }
            provider.setUser(id: id, properties: properties)
        }
        
        guard let crashProvider else { return }
        let remoteEnabled = shouldSendRemote(for: crashProvider)
        emitDebugEvent("set_user", info: [
            "provider": providerName(for: crashProvider),
            "id": id ?? "nil",
            "properties": properties,
            "remote_enabled": remoteEnabled
        ])
        guard remoteEnabled else { return }
        ensureCrashProviderStartedIfNeeded()
        crashProvider.setUser(id: id, properties: properties)
    }

    public func track(name: String, properties: [String: Any]? = nil) {
        guard !optedOut else {
            emitDebugEvent("track_skipped", info: [
                "reason": "opt_out",
                "name": name,
                "properties": properties ?? [:]
            ])
            return
        }
        
        for provider in analyticsProviders {
            let remoteEnabled = shouldSendRemote(for: provider)
            emitDebugEvent("track", info: [
                "provider": providerName(for: provider),
                "name": name,
                "properties": properties ?? [:],
                "remote_enabled": remoteEnabled
            ])
            guard remoteEnabled else { continue }
            provider.track(name: name, properties: properties)
        }
    }

    public func logError(_ error: Error, context: [String: Any]? = nil) {
        guard !optedOut else {
            emitDebugEvent("log_error_skipped", info: [
                "reason": "opt_out",
                "error": String(describing: error),
                "context": context ?? [:]
            ])
            return
        }
        guard let crashProvider else { return }
        
        let remoteEnabled = shouldSendRemote(for: crashProvider)
        emitDebugEvent("log_error", info: [
            "provider": providerName(for: crashProvider),
            "error": String(describing: error),
            "context": context ?? [:],
            "remote_enabled": remoteEnabled
        ])
        
        guard remoteEnabled else { return }
        ensureCrashProviderStartedIfNeeded()
        crashProvider.capture(error: error, context: context)
    }

    public func logMessage(_ message: String, context: [String: Any]? = nil) {
        guard !optedOut else {
            emitDebugEvent("log_message_skipped", info: [
                "reason": "opt_out",
                "message": message,
                "context": context ?? [:]
            ])
            return
        }
        guard let crashProvider else { return }
        
        let remoteEnabled = shouldSendRemote(for: crashProvider)
        emitDebugEvent("log_message", info: [
            "provider": providerName(for: crashProvider),
            "message": message,
            "context": context ?? [:],
            "remote_enabled": remoteEnabled
        ])
        
        guard remoteEnabled else { return }
        ensureCrashProviderStartedIfNeeded()
        crashProvider.capture(message: message, context: context)
    }

    public func flush() {
        for provider in analyticsProviders {
            let remoteEnabled = shouldSendRemote(for: provider)
            emitDebugEvent("flush", info: [
                "provider": providerName(for: provider),
                "remote_enabled": remoteEnabled
            ])
            guard remoteEnabled else { continue }
            provider.flush()
        }
    }

    public func optOut(_ enabled: Bool) {
        optedOut = enabled
        emitDebugEvent("opt_out", info: ["enabled": enabled])
        analyticsProviders.forEach { $0.setOptOut(enabled) }
    }
    
    // MARK: - Debug Event Hooks
    
    /// Observe raw telemetry events for custom filtering and diagnostics.
    @discardableResult
    public func onRawEvent(_ handler: TelemetryRawEventHandler?) -> Self {
        rawEventHandler = handler
        return self
    }
    
    /// Observe pretty, formatted telemetry events.
    @discardableResult
    public func onPrettyEvent(
        formatter: @escaping TelemetryPrettyEventFormatter = TelemetryPrettyFormatter.default,
        _ handler: TelemetryPrettyEventHandler?
    ) -> Self {
        prettyEventFormatter = formatter
        prettyEventHandler = handler
        return self
    }
    
    /// Convenience helper for default console output.
    @discardableResult
    public func printEvents(_ enabled: Bool = true) -> Self {
        if enabled {
            return onPrettyEvent(formatter: TelemetryPrettyFormatter.default) { line in
                Swift.print(line)
            }
        }
        prettyEventHandler = nil
        return self
    }
    
    // MARK: - Global Debug/Remote Controls
    
    /// Default debug mode for all providers without a local override.
    @discardableResult
    public func debugMode(_ enabled: Bool) -> Self {
        globalDebugMode = enabled
        analyticsProviders.forEach { applyDebugModeIfSupported(to: $0) }
        if let crashProvider { applyDebugModeIfSupported(to: crashProvider) }
        emitDebugEvent("global_debug_mode", info: ["enabled": enabled])
        return self
    }
    
    /// Default remote behavior for debug builds for all providers without a local override.
    @discardableResult
    public func remoteInDebug(_ enabled: Bool) -> Self {
        globalRemoteInDebug = enabled
        ensureCrashProviderStartedIfNeeded()
        emitDebugEvent("global_remote_in_debug", info: ["enabled": enabled])
        return self
    }
    
    /// Convenience helper to disable or re-enable remote calls in debug builds.
    @discardableResult
    public func disableRemoteInDebug(_ disabled: Bool = true) -> Self {
        remoteInDebug(!disabled)
    }

    // MARK: - Static forwarder
    public static func track(name: String, properties: [String: Any]? = nil) {
        Telemetry.shared.track(name: name, properties: properties)
    }
    
    @discardableResult
    public static func printEvents(_ enabled: Bool = true) -> Telemetry {
        Telemetry.shared.printEvents(enabled)
    }
    
    @discardableResult
    public static func debugMode(_ enabled: Bool) -> Telemetry {
        Telemetry.shared.debugMode(enabled)
    }
    
    @discardableResult
    public static func remoteInDebug(_ enabled: Bool) -> Telemetry {
        Telemetry.shared.remoteInDebug(enabled)
    }
    
    @discardableResult
    public static func disableRemoteInDebug(_ disabled: Bool = true) -> Telemetry {
        Telemetry.shared.disableRemoteInDebug(disabled)
    }
    
    // MARK: - Internals
    
    private func emitDebugEvent(_ event: String, info: [String: Any]) {
        let payload = TelemetryDebugEvent(event: event, info: info)
        rawEventHandler?(payload)
        if let prettyEventHandler {
            prettyEventHandler(prettyEventFormatter(payload))
        }
    }
    
    private func providerName(for provider: Any) -> String {
        if let provider = provider as? TelemetryControllableProvider {
            return provider.telemetryProviderName
        }
        return String(describing: type(of: provider))
    }
    
    private func shouldSendRemote(for provider: Any) -> Bool {
        #if DEBUG
        if let provider = provider as? TelemetryControllableProvider,
           let localOverride = provider.telemetryControl.remoteInDebug {
            return localOverride
        }
        return globalRemoteInDebug
        #else
        _ = provider
        return true
        #endif
    }
    
    private func resolveDebugMode(for provider: Any) -> Bool {
        if let provider = provider as? TelemetryControllableProvider,
           let localOverride = provider.telemetryControl.debugMode {
            return localOverride
        }
        return globalDebugMode
    }
    
    private func applyDebugModeIfSupported(to provider: Any) {
        guard let debugAwareProvider = provider as? TelemetryDebugModeApplicable else { return }
        debugAwareProvider.applyDebugMode(resolveDebugMode(for: provider))
    }
    
    private func ensureCrashProviderStartedIfNeeded() {
        guard let crashProvider else { return }
        guard shouldSendRemote(for: crashProvider) else { return }
        guard !crashProviderStarted else { return }
        crashProvider.start()
        crashProviderStarted = true
        emitDebugEvent("crash_provider_started", info: [
            "provider": providerName(for: crashProvider)
        ])
    }
}
