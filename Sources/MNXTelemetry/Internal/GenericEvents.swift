//
//  GenericEvents.swift
//  MNXTelemetry
//
//  SPDX-License-Identifier: Apache-2.0
//  See the LICENSE file in the project root for license information.
//
//  Created by Nikita Moshyn on 02/10/2025.
//  Copyright © 2025 Nikita Moshyn. All rights reserved.
//

import Foundation

public enum GenericEvents: AnalyticsEvent {
    case screenView(name: String)
    
    public var name: String {
        switch self {
        case .screenView:
            return "screen_view"
        }
    }
    
    public var properties: [String: Any] {
        switch self {
        case .screenView(name: let name):
            return ["screen_name": name]
        }
        
    }
}
