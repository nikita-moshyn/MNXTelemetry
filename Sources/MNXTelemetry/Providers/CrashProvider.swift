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

public protocol CrashProvider {
    func start()
    func setUser(id: String?, properties: [String: Any])
    func capture(error: Error, context: [String: Any]?)
    func capture(message: String, context: [String: Any]?)
}
