//
//  Flags.swift
//  MNXTelemetry
//
//  SPDX-License-Identifier: Apache-2.0
//  See the LICENSE file in the project root for license information.
//
//  Created by Nikita Moshyn on 28/09/2025.
//  Copyright © 2025 Nikita Moshyn. All rights reserved.
//

import Foundation

public final class Flags {
    public static let shared = Flags()
    private init() {}

    public enum Mode {
        case local(defaults: [String: Any])
        case remote(endpoint: URL, cacheTTL: TimeInterval = 300)
    }

    private var store: [String: Any] = [:]
    private var mode: Mode = .local(defaults: [:])
    private var lastFetch: Date?
    private var exposureHook: ((String, String, [String: Any]?) -> Void)?

    public func configure(_ mode: Mode,
                          exposureHook: ((String, String, [String: Any]?) -> Void)? = { exp, varnt, props in
        Telemetry.track(name: "experiment_exposed",
                        properties: ["experiment": exp, "variant": varnt].merging(props ?? [:], uniquingKeysWith: { _, new in new }))
    }) {
        self.mode = mode
        self.exposureHook = exposureHook
        switch mode {
        case .local(let defaults):
            store = defaults
        case .remote(let endpoint, _):
            _ = try? fetchRemote(endpoint: endpoint)
        }
    }

    public func isEnabled(_ key: String, default defaultValue: Bool = false) -> Bool {
        (store[key] as? Bool) ?? defaultValue
    }

    public func variant(_ key: String, default defaultValue: String? = nil) -> String? {
        store[key] as? String ?? defaultValue
    }

    @discardableResult
    public func refresh() -> Bool {
        guard case .remote(let endpoint, let ttl) = mode else { return false }
        let now = Date()
        if let last = lastFetch, now.timeIntervalSince(last) < ttl { return false }
        do { try fetchRemote(endpoint: endpoint); return true } catch { return false }
    }

    public func notifyExposure(experiment: String, variant: String, props: [String: Any]? = nil) {
        exposureHook?(experiment, variant, props)
    }

    // NOTE: Replace with async URLSession in production
    private func fetchRemote(endpoint: URL) throws {
        let data = try Data(contentsOf: endpoint)
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        if let dict = json as? [String: Any] {
            store.merge(dict) { _, new in new }
            lastFetch = Date()
        }
    }
}
