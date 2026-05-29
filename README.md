# OpenConstruct Swift

Swift binding for OpenConstruct onboarding — built for iOS/macOS agent apps and the broader Apple ecosystem.

## Installation

Add the dependency in your `Package.swift`:

```swift
.package(url: "https://github.com/SuperInstance/openconstruct-swift.git", from: "1.0.0")
```

## Usage

```swift
import OpenConstruct

// Create a client
let client = OpenConstructClient()

// Run the onboarding phase flow
try client.start()
let identity = AgentIdentity(name: "my-agent", model: "glm-5.1", capabilities: ["code_generation"])
try client.declareAgent(identity)

// Discover and select modules
let mathModules = client.listModules(domain: "math")
try client.selectModules(["spectral-graph-core", "plato-room"])

// Choose interface and generate config
try client.chooseInterface("api")
let config = try client.generateConfig()
```

### One-shot convenience

```swift
let config = try client.onboard(
    identity: AgentIdentity(name: "my-agent", model: "glm-5.1"),
    moduleIds: ["spectral-graph-core"],
    interface: "cli"
)
```

## Phase Lifecycle

```
idle → started → agentDeclared → modulesSelected → interfaceChosen → configGenerated
```

Each phase method validates that the previous phase has been completed and throws `OpenConstructError` on invalid transitions.

## API

| Type | Description |
|---|---|
| `OpenConstructClient` | Main client with phase-flow methods |
| `AgentIdentity` | Agent name, model, and capabilities |
| `ModuleInfo` | Module metadata (id, name, domain) |
| `ModuleRegistry` | Registry with domain filtering |
| `OnboardingConfig` | Final config output |
| `Phase` | Lifecycle phase enum |
| `OpenConstructError` | Error type for phase violations |

## License

MIT
