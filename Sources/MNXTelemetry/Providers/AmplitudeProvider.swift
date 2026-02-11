//
//  AmplitudeProvider.swift
//  MNXTelemetry
//
//  SPDX-License-Identifier: Apache-2.0
//  See the LICENSE file in the project root for license information.
//
//  Created by Nikita Moshyn on 28/09/2025.
//  Copyright © 2025 Nikita Moshyn. All rights reserved.
//

import Foundation
internal import AmplitudeSwift

public final class AmplitudeProvider: AnalyticsProvider, TelemetryLifecycleStartable, TelemetryControllableProvider, TelemetryDebugModeApplicable {
    private let apiKey: String
    private let serverZone: AmplitudeServerZone
    
    private var amplitude: Amplitude?
    private var pendingOptOut = false
    public var telemetryControl = TelemetryProviderControl()

    public init(apiKey: String, serverZone: AmplitudeServerZone = .EU) {
        self.apiKey = apiKey
        self.serverZone = serverZone
    }

    public func start() {
        guard amplitude == nil else { return }
        let instance = Amplitude(configuration: .init(apiKey: apiKey, serverZone: serverZone.serverZone))
        instance.optOut = pendingOptOut
        amplitude = instance
    }

    public func track(name: String, properties: [String : Any]?) {
        guard let amplitude else { return }
        amplitude.track(eventType: name, eventProperties: properties)
        // TODO: Amplitude logEvent(name, withEventProperties: properties)
    }

    public func setUser(id: String?, properties: [String : Any]) {
        guard let amplitude else { return }
        amplitude.setUserId(userId: id)
        guard !properties.isEmpty else { return }
        let identify = Identify()
        for (key, value) in properties {
            _ = identify.set(property: key, value: value)
        }
        amplitude.identify(identify: identify)
    }

    public func flush() {
        guard let amplitude else { return }
        amplitude.flush()
        // TODO: optional (Amplitude often batches automatically)
    }

    public func setOptOut(_ enabled: Bool) {
        pendingOptOut = enabled
        amplitude?.optOut = enabled
        // TODO: set opt-out on Amplitude instance
    }
    
    public func applyDebugMode(_ enabled: Bool) {
        // AmplitudeSwift does not currently expose a stable runtime debug switch across versions.
        // Keep this value so the framework has a consistent provider-level debug API.
        _ = enabled
    }
}

public enum AmplitudeServerZone {
    case EU
    case US
    
    internal var serverZone: ServerZone {
        switch self {
        case .EU: .EU
        case .US: .US
        }
    }
}
