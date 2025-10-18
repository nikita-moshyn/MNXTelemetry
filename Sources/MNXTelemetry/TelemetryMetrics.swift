//
//  TelemetryMetrics.swift
//  MNXTelemetry
//
//  SPDX-License-Identifier: Apache-2.0
//  See the LICENSE file in the project root for license information.
//
//  Created by Nikita Moshyn on 29/09/2025.
//  Copyright © 2025 Nikita Moshyn. All rights reserved.
//

import Foundation

// MARK: - Public API (available on all platforms, stubs if MetricKit not present)

/// Options to control how MetricKit data is forwarded to analytics.
public struct TelemetryMetricsOptions {
    /// Forward summarized launch metrics into `Telemetry` as events.
    public var forwardLaunchSummaries: Bool = true
    /// Event name for launch summaries.
    public var launchSummaryEventName: String = "mx_launch_summary"
    /// Sample [0, 1]. 1.0 = send all summaries; 0.1 = ~10%.
    public var sampling: Double = 1.0
    /// Attach build/version in the properties (if available from payload).
    public var includeBuildInfo: Bool = true

    public init() {}
}

/// Facade you can start/stop from your app to receive MetricKit payloads.
public protocol TelemetryMetricsProtocol: AnyObject {
    func start(options: TelemetryMetricsOptions)
    func stop()
}

#if canImport(MetricKit)
import MetricKit

/// Real implementation when MetricKit is available.
public final class TelemetryMetrics: NSObject, TelemetryMetricsProtocol, MXMetricManagerSubscriber {
    nonisolated(unsafe) public static let shared = TelemetryMetrics()
    private override init() {}

    private var isStarted = false
    private var options = TelemetryMetricsOptions()

    // MARK: - Lifecycle

    public func start(options: TelemetryMetricsOptions = .init()) {
        guard !isStarted else { return }
        self.options = options
        MXMetricManager.shared.add(self)
        isStarted = true
    }

    public func stop() {
        guard isStarted else { return }
        MXMetricManager.shared.remove(self)
        isStarted = false
    }

    // MARK: - MXMetricManagerSubscriber (Metrics)

    /// Called roughly once per day with aggregated performance metrics.
    public func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            guard shouldSample() else { continue }

            // --- Summarize launch times (cold/warm) if available ---
            if let summary = summarizeLaunch(from: payload) {
                var props: [String: Any] = [
                    "cold_p50_ms": summary.cold.p50MS ?? NSNull(),
                    "cold_p95_ms": summary.cold.p95MS ?? NSNull(),
                    "warm_p50_ms": summary.warm.p50MS ?? NSNull(),
                    "warm_p95_ms": summary.warm.p95MS ?? NSNull()
                ]
                if options.includeBuildInfo, let build = payload.value(forKeyPath: "metadata.applicationBuildVersion") as? String {
                    props["build"] = build
                }
                if options.forwardLaunchSummaries {
                    Telemetry.shared.track(name: options.launchSummaryEventName, properties: props)
                }
            }

            // You can extend here: memory/CPU/animation hitch summaries if you want.
        }
    }

    // MARK: - MXMetricManagerSubscriber (Diagnostics)

    /// Called periodically with aggregated diagnostics (crashes/OOM/hangs, etc.).
    public func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for diag in payloads {
            guard shouldSample() else { continue }

            // Count diagnostics by type (avoid huge payloads)
            let crashCount = (diag.value(forKey: "crashDiagnostics") as? [Any])?.count ?? 0
            let cpuExCount = (diag.value(forKey: "cpuExceptionDiagnostics") as? [Any])?.count ?? 0
            let hangCount  = (diag.value(forKey: "hangDiagnostics") as? [Any])?.count ?? 0
            let diskCount  = (diag.value(forKey: "diskWriteExceptionDiagnostics") as? [Any])?.count ?? 0
            let exitCount  = (diag.value(forKey: "applicationExitDiagnostics") as? [Any])?.count ?? 0

            var props: [String: Any] = [
                "crash_count": crashCount,
                "cpu_exception_count": cpuExCount,
                "hang_count": hangCount,
                "disk_write_exception_count": diskCount,
                "app_exit_count": exitCount
            ]
            if options.includeBuildInfo, let build = diag.value(forKeyPath: "metadata.applicationBuildVersion") as? String {
                props["build"] = build
            }

            // Use a dedicated event name for diagnostics summary
            Telemetry.shared.track(name: "mx_diagnostic_summary", properties: props)
        }
    }

    // MARK: - Helpers

    private func shouldSample() -> Bool {
        guard options.sampling < 1.0 else { return true }
        return Double.random(in: 0...1) < max(0.0, min(1.0, options.sampling))
    }

    /// Summarize cold/warm launch histograms from the payload via KVC (avoids API version fragility).
    private func summarizeLaunch(from payload: MXMetricPayload) -> LaunchSummary? {
        // Both "applicationLaunch" and "appLaunch" have existed at various points; try both.
        let appLaunch: AnyObject? =
            (payload.value(forKey: "applicationLaunch") as AnyObject?) ??
            (payload.value(forKey: "appLaunch") as AnyObject?)

        guard let launch = appLaunch else { return nil }

        // histogrammedTimeToFirstDraw contains { coldLaunch, warmLaunch } histograms.
        guard let ttfDraw = launch.value(forKey: "histogrammedTimeToFirstDraw") as AnyObject? else { return nil }

        let coldHist = ttfDraw.value(forKey: "coldLaunch") as AnyObject?
        let warmHist = ttfDraw.value(forKey: "warmLaunch") as AnyObject?

        let cold = summarizeHistogramSeconds(coldHist)
        let warm = summarizeHistogramSeconds(warmHist)

        if cold.isEmpty && warm.isEmpty { return nil }
        return LaunchSummary(
            cold: .init(p50MS: percentile(cold, 0.50), p95MS: percentile(cold, 0.95)),
            warm: .init(p50MS: percentile(warm, 0.50), p95MS: percentile(warm, 0.95))
        )
    }

    /// Extract buckets as (start, end, count) in **seconds** using KVC.
    private func extractBucketsSeconds(_ histogram: AnyObject) -> [(start: Double, end: Double, count: UInt64)] {
        guard let enumerator = histogram.value(forKey: "bucketEnumerator") as? NSEnumerator else { return [] }
        var buckets: [(start: Double, end: Double, count: UInt64)] = []
        while let obj = enumerator.nextObject() as AnyObject? {
            let start = (obj.value(forKey: "bucketStart") as? NSNumber)?.doubleValue ?? 0
            let end   = (obj.value(forKey: "bucketEnd") as? NSNumber)?.doubleValue ?? start
            let cnt   = (obj.value(forKey: "bucketCount") as? NSNumber)?.uint64Value ?? 0
            buckets.append((start, end, cnt))
        }
        // Ensure sorted by start
        return buckets.sorted { $0.start < $1.start }
    }

    /// Convert a histogram object into a simple array of buckets (seconds).
    private func summarizeHistogramSeconds(_ histogram: AnyObject?) -> [(midpointSec: Double, count: UInt64)] {
        guard let histogram else { return [] }
        let raw = extractBucketsSeconds(histogram)
        return raw.map { ( ($0.start + $0.end) / 2.0, $0.count ) }
    }

    /// Compute percentile (e.g., 0.50, 0.95) from (midpointSec, count) pairs; returns **milliseconds**.
    private func percentile(_ data: [(midpointSec: Double, count: UInt64)], _ p: Double) -> Int? {
        guard !data.isEmpty else { return nil }
        let total = data.reduce(0 as UInt64) { $0 + $1.count }
        guard total > 0 else { return nil }

        let threshold = Double(total) * p
        var cumulative: Double = 0
        for (mid, count) in data {
            cumulative += Double(count)
            if cumulative >= threshold {
                return Int(mid * 1000.0) // sec → ms
            }
        }
        // Fallback to max midpoint
        return Int((data.last?.midpointSec ?? 0) * 1000.0)
    }

    // MARK: - Types

    private struct LaunchSummary {
        struct Slice { let p50MS: Int?; let p95MS: Int? }
        let cold: Slice
        let warm: Slice
    }
}

#else

// Fallback stub when MetricKit isn't available (e.g., certain platforms or unit tests).
public final class TelemetryMetrics: TelemetryMetricsProtocol {
    public static let shared = TelemetryMetrics()
    private init() {}

    public func start(options: TelemetryMetricsOptions = .init()) {
        // No-op: MetricKit not available on this platform/toolchain.
        #if DEBUG
        print("[TelemetryMetrics] MetricKit not available; start() is a no-op.")
        #endif
    }

    public func stop() {
        // No-op
    }
}
#endif
