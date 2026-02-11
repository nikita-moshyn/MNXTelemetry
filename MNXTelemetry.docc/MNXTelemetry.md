# ``MNXTelemetry``

Unified telemetry router for analytics, crashes, and debug event inspection.

## Overview

`MNXTelemetry` can forward analytics/crash events to providers and also expose local debug hooks.

Raw + pretty debug events:

```swift
Telemetry.shared
    .onRawEvent { raw in
        print(raw.event, raw.info)
    }
    .printEvents() // event: <name>, info: <payload>
```

Global defaults:

```swift
Telemetry.shared
    .debugMode(false)
    .disableRemoteInDebug()
```

Per-provider overrides:

```swift
let sentry = SentryCrashProvider(dsn: "<dsn>")
    .debugMode(false)
    .remoteInDebug(true)

let amplitude = AmplitudeProvider(apiKey: "<key>")
    .debugMode(false)
    .disableRemote()

Telemetry.shared.register(crashProvider: sentry)
Telemetry.shared.register(provider: amplitude)
Telemetry.shared.start()
```

## Topics

### Core

- ``Telemetry``
- ``TypedTelemetry``
- ``AnalyticsEvent``

### Debug Hooks

- ``TelemetryDebugEvent``
- ``TelemetryPrettyFormatter``

### Provider Controls

- ``TelemetryProviderControl``
- ``TelemetryControllableProvider``
- ``TelemetryDebugModeApplicable``
- ``TelemetryLifecycleStartable``
