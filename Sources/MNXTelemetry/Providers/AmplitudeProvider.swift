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

public final class AmplitudeProvider: AnalyticsProvider {
    private let apiKey: String
    
    private let amplitude: Amplitude

    public init(apiKey: String, serverZone: AmplitudeServerZone = .EU) {
        self.apiKey = apiKey
        self.amplitude = Amplitude(configuration: .init(apiKey: apiKey, serverZone: serverZone.serverZone))
        // TODO: Initialize Amplitude SDK (identify instance, enable batching)
    }

    public func track(name: String, properties: [String : Any]?) {
        amplitude.track(eventType: name, eventProperties: properties)
        // TODO: Amplitude logEvent(name, withEventProperties: properties)
    }

    public func setUser(id: String?, properties: [String : Any]) {
        amplitude.setUserId(userId: id)
        // TODO: setUserId + identify object to set user properties
    }

    public func flush() {
        amplitude.flush()
        // TODO: optional (Amplitude often batches automatically)
    }

    public func setOptOut(_ enabled: Bool) {
        amplitude.optOut = enabled
        // TODO: set opt-out on Amplitude instance
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
