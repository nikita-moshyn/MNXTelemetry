//
//  PostHogProvider.swift
//  MNXTelemetry
//
//  SPDX-License-Identifier: Apache-2.0
//  See the LICENSE file in the project root for license information.
//
//  Created by Nikita Moshyn on 28/09/2025.
//  Copyright © 2025 Nikita Moshyn. All rights reserved.
//

import Foundation

public final class PostHogProvider: AnalyticsProvider {
    private let apiKey: String
    private let host: URL

    public init(apiKey: String, host: URL) {
        self.apiKey = apiKey
        self.host = host
        fatalError("Not supported yet")
        // TODO: Initialize PostHog SDK (host, apiKey)
    }

    public func track(name: String, properties: [String : Any]?) {
        // TODO: capture(name, properties)
    }

    public func setUser(id: String?, properties: [String : Any]) {
        // TODO: identify(id, properties)
    }

    public func flush() {
        // TODO: flush if available
    }

    public func setOptOut(_ enabled: Bool) {
        // TODO: opt-out
    }
}
