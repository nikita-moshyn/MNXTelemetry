//
//  AnalyticsEvent.swift
//  MNXTelemetry
//
//  SPDX-License-Identifier: Apache-2.0
//  See the LICENSE file in the project root for license information.
//
//  Created by Nikita Moshyn on 28/09/2025.
//  Copyright © 2025 Nikita Moshyn. All rights reserved.
//

import Foundation

// MARK: - Typed Event Protocol

/// Strongly-typed analytics event.
/// Implement `name` and (optionally) `properties` to describe the event payload.
public protocol AnalyticsEvent {
    /// Event name as sent to providers (e.g., "add_card_completed").
    var name: String { get }
    /// Key-value payload. Defaults to empty.
    var properties: [String: Any] { get }
}

public extension AnalyticsEvent {
    var properties: [String: Any] { [:] }
}
