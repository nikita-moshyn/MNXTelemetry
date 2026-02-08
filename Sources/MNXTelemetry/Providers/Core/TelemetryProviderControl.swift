//
//  TelemetryProviderControl.swift
//  MNXTelemetry
//
//  SPDX-License-Identifier: Apache-2.0
//  See the LICENSE file in the project root for license information.
//
//  Created by Codex on 08/02/2026.
//

import Foundation

/// Per-provider runtime overrides used by ``Telemetry``.
public struct TelemetryProviderControl {
    /// Provider-specific debug mode override. `nil` means "use telemetry global value".
    public var debugMode: Bool?
    /// Provider-specific remote behavior in debug builds. `nil` means "use telemetry global value".
    public var remoteInDebug: Bool?

    public init(debugMode: Bool? = nil, remoteInDebug: Bool? = nil) {
        self.debugMode = debugMode
        self.remoteInDebug = remoteInDebug
    }
}

/// Adopt on providers that want per-provider debug/remote overrides.
public protocol TelemetryControllableProvider: AnyObject {
    var telemetryControl: TelemetryProviderControl { get set }
    var telemetryProviderName: String { get }
}

public extension TelemetryControllableProvider {
    var telemetryProviderName: String { String(describing: type(of: self)) }

    /// Override debug mode for this provider.
    @discardableResult
    func debugMode(_ enabled: Bool) -> Self {
        telemetryControl.debugMode = enabled
        return self
    }

    /// Override "remote enabled in debug build" for this provider.
    @discardableResult
    func remoteInDebug(_ enabled: Bool) -> Self {
        telemetryControl.remoteInDebug = enabled
        return self
    }

    /// Convenience helper to disable or re-enable remote in debug builds.
    @discardableResult
    func disableRemoteInDebug(_ disabled: Bool = true) -> Self {
        telemetryControl.remoteInDebug = !disabled
        return self
    }
}

/// Implement when a provider can map telemetry debug mode to underlying SDK options.
public protocol TelemetryDebugModeApplicable: AnyObject {
    func applyDebugMode(_ enabled: Bool)
}
