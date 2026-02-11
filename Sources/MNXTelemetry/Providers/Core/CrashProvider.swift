//
//  CrashProvider.swift
//  MNXTelemetry
//
//  SPDX-License-Identifier: Apache-2.0
//  See the LICENSE file in the project root for license information.
//
//  Created by Nikita Moshyn on 28/09/2025.
//  Copyright © 2025 Nikita Moshyn. All rights reserved.
//

import Foundation

/// Adopt on providers that should be initialized lazily by `Telemetry.start()`.
public protocol TelemetryLifecycleStartable: AnyObject {
    func start()
}

public protocol CrashProvider: TelemetryLifecycleStartable {
    func setUser(id: String?, properties: [String: Any])
    func capture(error: Error, context: [String: Any]?)
    func capture(message: String, context: [String: Any]?)
}
