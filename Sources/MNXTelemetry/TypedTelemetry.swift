//
//  TypedTelemetry.swift
//  MNXTelemetry
//
//  SPDX-License-Identifier: Apache-2.0
//  See the LICENSE file in the project root for license information.
//
//  Created by Nikita Moshyn on 28/09/2025.
//  Copyright © 2025 Nikita Moshyn. All rights reserved.
//

import Foundation

/// Generic facade that forwards typed events to the untyped `Telemetry` core.
/// Usage options:
/// 1) Inline type context
///    `Telemetry.typed(OnlyCardsEvents.self).track(.appOpen)`
/// 2) Shorthand generic alias
///    `TypedTelemetry<OnlyCardsEvents>.track(.appOpen)`
/// 3) App-bound alias (in your app target):
///    `typealias EventTelemetry = TypedTelemetry<OnlyCardsEvents>` then `EventTelemetry.track(.appOpen)`
public struct TypedTelemetry<Event: AnalyticsEvent> {
    /// Create an instance-bound facade (useful for DI/tests). Most users will prefer the static methods.
    public init() {}

    // MARK: Instance API

    /// Track a typed event via the shared Telemetry router.
    @inline(__always)
    public func track(_ event: Event) {
        Telemetry.shared.track(name: event.name, properties: event.properties)
    }

    /// Identify the user (for convenience; forwards to `Telemetry.shared`).
    public func setUser(id: String?, properties: [String: Any] = [:]) {
        Telemetry.shared.setUser(id: id, properties: properties)
    }

    /// Log a non-fatal error.
    public func logError(_ error: Error, context: [String: Any]? = nil) {
        Telemetry.shared.logError(error, context: context)
    }

    /// Flush queued events (best effort; provider-specific).
    public func flush() {
        Telemetry.shared.flush()
    }

    // MARK: Static convenience API

    /// Track without creating an instance: `TypedTelemetry<OnlyCardsEvents>.track(.appOpen)`
    @inline(__always)
    public static func track(_ event: Event) {
        Telemetry.shared.track(name: event.name, properties: event.properties)
    }
}

// MARK: - Ergonomics

public extension Telemetry {
    /// Factory to get a typed facade bound to a specific event enum.
    /// Example: `let T = Telemetry.typed(OnlyCardsEvents.self); T.track(.appOpen)`
    static func typed<E: AnalyticsEvent>(_ type: E.Type) -> TypedTelemetry<E> { .init() }
}

/// Shorthand generic alias so you can write `EventTelemetry<MyAppEvents>.track(...)`.
//public typealias EventTelemetry<E: AnalyticsEvent> = TypedTelemetry<E>
