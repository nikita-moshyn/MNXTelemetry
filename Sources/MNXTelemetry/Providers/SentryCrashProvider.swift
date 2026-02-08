//
//  SentryCrashProvider.swift
//  MNXTelemetry
//
//  SPDX-License-Identifier: Apache-2.0
//  See the LICENSE file in the project root for license information.
//
//  Created by Nikita Moshyn on 28/09/2025.
//  Copyright © 2025 Nikita Moshyn. All rights reserved.
//

import Foundation
internal import Sentry

public final class SentryCrashProvider: CrashProvider, TelemetryControllableProvider, TelemetryDebugModeApplicable {
    private let dsn: String
    private let environment: String?
    public var telemetryControl = TelemetryProviderControl()
    private var sdkDebugMode: Bool = {
        #if DEBUG
        true
        #else
        false
        #endif
    }()

    public init(dsn: String, environment: String? = nil) {
        self.dsn = dsn
        self.environment = environment
    }

    public func start() {
        SentrySDK.start { options in
            options.dsn = self.dsn
            if let env = self.environment {
                options.environment = env
            }
            options.debug = self.sdkDebugMode
            // Enable automatic session tracking so crashes and sessions are correlated.
            options.enableAutoSessionTracking = true
            // Privacy note: leave PII off unless you have a clear need and disclosure.
            // options.sendDefaultPii = true
        }
    }
    
    public func setUser(id: String?, properties: [String : Any]) {
        guard let id else { return }
        SentrySDK.configureScope { scope in
            scope.setUser(User(userId: id))
            properties.forEach { scope.setExtra(value: $0.value, key: "user.\($0.key)") }
        }
    }

    public func capture(error: Error, context: [String : Any]?) {
        SentrySDK.capture(error: error) { scope in
            if let ctx = context {
                for (key, value) in ctx { scope.setExtra(value: value, key: key) }
            }
        }
    }

    public func capture(message: String, context: [String : Any]?) {
        SentrySDK.capture(message: message) { scope in
            if let ctx = context {
                for (key, value) in ctx { scope.setExtra(value: value, key: key) }
            }
        }
    }
    
    public func applyDebugMode(_ enabled: Bool) {
        sdkDebugMode = enabled
    }
}
