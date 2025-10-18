//
//  String.swift
//  MNXTelemetry
//
//  SPDX-License-Identifier: Apache-2.0
//  See the LICENSE file in the project root for license information.
//
//  Created by Nikita Moshyn on 02/10/2025.
//  Copyright © 2025 Nikita Moshyn. All rights reserved.
//

import Foundation

extension String {
    /// Converts "SettingsView" -> "settings_view", "AddCardView" -> "add_card_view"
    /// and trims a trailing "View" for cleaner screen names.
    func analyticsSlug() -> String {
        let trimmed = self.replacingOccurrences(
            of: #"View$"#,
            with: "",
            options: .regularExpression
        )
        let pattern = "([a-z0-9])([A-Z])"
        let underscored = trimmed.replacingOccurrences(
            of: pattern,
            with: "$1_$2",
            options: .regularExpression
        )
        return underscored.lowercased()
    }
}
