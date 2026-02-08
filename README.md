# MNXTelemetry
Unified Telemetry (Events + Crashes + Flags) for Apple Platforms

## Debug event hooks (raw + pretty)

```swift
Telemetry.shared
    .onRawEvent { event in
        // Raw payload, you can filter/transform however you want.
        print("raw title:", event.event)
    }
    .printEvents() // default pretty formatter: "event: ..., info: ..."
```

Custom pretty formatter:

```swift
Telemetry.shared.onPrettyEvent(formatter: { event in
    "event: \(event.event)"
}) { line in
    print(line)
}
```

## Provider debug and remote controls

Global defaults for all providers:

```swift
Telemetry.shared
    .debugMode(false)
    .disableRemoteInDebug() // same as .remoteInDebug(false)
```

Per-provider overrides (recommended before `register(...)`):

```swift
let sentry = SentryCrashProvider(dsn: "<dsn>")
    .debugMode(false)
    .remoteInDebug(true) // keep Sentry remote in Debug

let amplitude = AmplitudeProvider(apiKey: "<key>")
    .debugMode(false)
    .disableRemoteInDebug() // keep local-only in Debug

Telemetry.shared.register(crashProvider: sentry)
Telemetry.shared.register(provider: amplitude)
```
