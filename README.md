# OpenConstruct Swift — Apple Ecosystem Binding

Swift client for [OpenConstruct](https://github.com/SuperInstance/OpenConstruct). Built for iOS/macOS agent apps and the broader Apple ecosystem.

## What This Gives You

- **5-phase onboarding** — enforced lifecycle with `OpenConstructError` on violations
- **One-shot convenience** — `client.onboard(identity:moduleIds:interface:)` for quick setup
- **Swift Package Manager** — add as a dependency in `Package.swift`
- **Value types** — `AgentIdentity`, `ModuleInfo`, `OnboardingConfig` as structs

## Quick Start

```swift
import OpenConstruct

let client = OpenConstructClient()

try client.start()
let identity = AgentIdentity(name: "my-agent", model: "glm-5.1", capabilities: ["code_generation"])
try client.declareAgent(identity)

let mathModules = client.listModules(domain: "math")
try client.selectModules(["spectral-graph-core", "plato-room"])
try client.chooseInterface("api")

let config = try client.generateConfig()
```

### One-Shot

```swift
let config = try client.onboard(
    identity: AgentIdentity(name: "my-agent", model: "glm-5.1"),
    moduleIds: ["spectral-graph-core"],
    interface: "cli"
)
```

## Installation

```swift
.package(url: "https://github.com/SuperInstance/openconstruct-swift.git", from: "1.0.0")
```

## Testing

```bash
swift test
```

## License

MIT
