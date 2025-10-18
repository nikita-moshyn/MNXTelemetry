//
//  AnalyticsProvider.swift
//  MNXTelemetry
//
//  SPDX-License-Identifier: Apache-2.0
//  See the LICENSE file in the project root for license information.
//
//  Created by Nikita Moshyn on 28/09/2025.
//  Copyright © 2025 Nikita Moshyn. All rights reserved.
//

import Foundation

public protocol AnalyticsProvider {
    func track(name: String, properties: [String: Any]?)
    func setUser(id: String?, properties: [String: Any])
    func flush()
    func setOptOut(_ enabled: Bool)
}
