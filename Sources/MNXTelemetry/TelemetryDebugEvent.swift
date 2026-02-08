//
//  TelemetryDebugEvent.swift
//  MNXTelemetry
//
//  SPDX-License-Identifier: Apache-2.0
//  See the LICENSE file in the project root for license information.
//
//  Created by Codex on 08/02/2026.
//

import Foundation

/// Lightweight representation of a telemetry action for local debugging.
public struct TelemetryDebugEvent {
    /// Event title (e.g. `track`, `set_user`, `log_error`).
    public let event: String
    /// Additional payload for the event.
    public let info: [String: Any]

    public init(event: String, info: [String: Any] = [:]) {
        self.event = event
        self.info = info
    }
}

/// Raw callback that receives full event payload for custom filtering/formatting.
public typealias TelemetryRawEventHandler = (TelemetryDebugEvent) -> Void

/// Pretty callback that receives a pre-formatted string.
public typealias TelemetryPrettyEventHandler = (String) -> Void

/// Formatter closure used by pretty callbacks.
public typealias TelemetryPrettyEventFormatter = (TelemetryDebugEvent) -> String

public enum TelemetryPrettyFormatter {
    /// Default pretty formatter: `event: <name>, info: <payload>`.
    public static func `default`(_ event: TelemetryDebugEvent) -> String {
        "event: \(event.event), info: \(event.info)"
    }
}
