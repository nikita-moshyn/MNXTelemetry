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
    public static let shared = Telemetry()
    private init() {}
    
    private var analyticsProviders: [AnalyticsProvider] = []
    private var crashProvider: CrashProvider?
    private var optedOut = false
    
    // MARK: - Registration
    
    public func register(provider: AnalyticsProvider) {
        analyticsProviders.append(provider)
    }

    public func register(crashProvider: CrashProvider) {
        self.crashProvider = crashProvider
        crashProvider.start()
    }
    
    // MARK: - Public API

    public func setUser(id: String?, properties: [String: Any] = [:]) {
        guard !optedOut else { return }
        analyticsProviders.forEach { $0.setUser(id: id, properties: properties) }
        crashProvider?.setUser(id: id, properties: properties)
    }

    public func track(name: String, properties: [String: Any]? = nil) {
        guard !optedOut else { return }
        analyticsProviders.forEach { $0.track(name: name, properties: properties) }
    }

    public func logError(_ error: Error, context: [String: Any]? = nil) {
        guard !optedOut else { return }
        crashProvider?.capture(error: error, context: context)
    }

    public func logMessage(_ message: String, context: [String: Any]? = nil) {
        guard !optedOut else { return }
        crashProvider?.capture(message: message, context: context)
    }

    public func flush() {
        analyticsProviders.forEach { $0.flush() }
    }

    public func optOut(_ enabled: Bool) {
        optedOut = enabled
        analyticsProviders.forEach { $0.setOptOut(enabled) }
    }

    // MARK: - Static forwarder
    public static func track(name: String, properties: [String: Any]? = nil) {
        Telemetry.shared.track(name: name, properties: properties)
    }
}
