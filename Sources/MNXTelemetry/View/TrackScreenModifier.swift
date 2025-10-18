//
//  TrackScreenModifier.swift
//  MNXTelemetry
//
//  SPDX-License-Identifier: Apache-2.0
//  See the LICENSE file in the project root for license information.
//
//  Created by Nikita Moshyn on 02/10/2025.
//  Copyright © 2025 Nikita Moshyn. All rights reserved.
//

import SwiftUI

/// Tracks screen views using the source file name at the call site to avoid SwiftUI wrapper types.
private struct TrackScreenModifier: ViewModifier {
    let explicitName: String?
    let fileID: StaticString

    @State private var hasTracked = false

    func body(content: Content) -> some View {
        content
            .onAppear {
            guard !hasTracked else { return }
            hasTracked = true

            let baseName = explicitName ?? deriveFromFileID(fileID)
            let slug = baseName.analyticsSlug()
            GenericEventTemetry.track(.screenView(name: slug))
        }
    }

    private func deriveFromFileID(_ fileID: StaticString) -> String {
        // Example: "OnlyCards/Features/Settings/SettingsView.swift" -> "SettingsView"
        let raw = String(describing: fileID)
        let last = raw.split(separator: "/").last.map(String.init) ?? raw
        return last.replacingOccurrences(of: ".swift", with: "")
    }
}

public extension View {
    /// Use `.trackScreen()` anywhere; it will send "settings" for `SettingsView.swift`, etc.
    /// - Parameters:
    ///   - name: Optional explicit override (e.g., "settings_v2").
    ///   - fileID: Do not pass manually; default captures the call-site file.
    func trackScreen(name: String? = nil, fileID: StaticString = #fileID) -> some View {
        modifier(TrackScreenModifier(explicitName: name, fileID: fileID))
    }
}
