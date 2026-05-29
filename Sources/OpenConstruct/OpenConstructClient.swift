import Foundation

// MARK: - Agent Identity

/// Represents the identity of an agent in the OpenConstruct ecosystem.
public struct AgentIdentity: Equatable, Codable {
    /// Unique name for the agent.
    public let name: String
    /// Model identifier (e.g. "glm-5.1").
    public let model: String
    /// List of capability strings the agent supports.
    public let capabilities: [String]

    public init(name: String, model: String, capabilities: [String] = []) {
        self.name = name
        self.model = model
        self.capabilities = capabilities
    }
}

// MARK: - Onboarding Config

/// The final onboarding configuration produced by the phase flow.
public struct OnboardingConfig: Equatable, Codable {
    /// Unique session identifier for this onboarding run.
    public let sessionId: String
    /// The agent identity that was declared.
    public let identity: AgentIdentity
    /// Modules selected during onboarding.
    public let modules: [ModuleInfo]
    /// Interface choice (e.g. "cli", "api", "embedded").
    public let interface: String
    /// Timestamp of config generation.
    public let generatedAt: Date

    public init(sessionId: String, identity: AgentIdentity, modules: [ModuleInfo], interface: String, generatedAt: Date = Date()) {
        self.sessionId = sessionId
        self.identity = identity
        self.modules = modules
        self.interface = interface
        self.generatedAt = generatedAt
    }
}

// MARK: - Module Info

/// Describes a module available in the registry.
public struct ModuleInfo: Equatable, Codable {
    /// Unique module identifier.
    public let id: String
    /// Human-readable name.
    public let name: String
    /// Domain category (e.g. "math", "language", "vision").
    public let domain: String
    /// Short description.
    public let description: String

    public init(id: String, name: String, domain: String, description: String = "") {
        self.id = id
        self.name = name
        self.domain = domain
        self.description = description
    }
}

// MARK: - Phase

/// Represents the current phase in the onboarding lifecycle.
public enum Phase: Int, Equatable, Comparable {
    case idle = 0
    case started = 1
    case agentDeclared = 2
    case modulesSelected = 3
    case interfaceChosen = 4
    case configGenerated = 5

    public static func < (lhs: Phase, rhs: Phase) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Errors

/// Errors thrown by `OpenConstructClient`.
public enum OpenConstructError: Error, Equatable {
    case invalidPhaseTransition(from: Phase, to: Phase)
    case agentNotDeclared
    case modulesNotSelected
    case interfaceNotChosen
    case notStarted
    case moduleNotFound(String)
    case noModulesSelected
}

// MARK: - Module Registry

/// Registry of available modules with domain filtering.
public struct ModuleRegistry {
    private var modules: [ModuleInfo] = []

    public init() {}

    /// Register a module.
    public mutating func register(_ module: ModuleInfo) {
        modules.append(module)
    }

    /// List all registered modules, optionally filtered by domain.
    public func listModules(domain: String? = nil) -> [ModuleInfo] {
        guard let domain = domain else { return modules }
        return modules.filter { $0.domain == domain }
    }

    /// Look up a module by ID.
    public func module(withId id: String) -> ModuleInfo? {
        modules.first { $0.id == id }
    }
}

// MARK: - OpenConstruct Client

/// Main client for the OpenConstruct onboarding phase flow.
///
/// Phase lifecycle:
/// `idle → started → agentDeclared → modulesSelected → interfaceChosen → configGenerated`
public final class OpenConstructClient {
    /// Current phase in the lifecycle.
    public private(set) var phase: Phase = .idle

    /// Unique session identifier, assigned on `start()`.
    public private(set) var sessionId: String?

    /// The declared agent identity.
    public private(set) var identity: AgentIdentity?

    /// Selected module IDs.
    public private(set) var selectedModuleIds: [String] = []

    /// Chosen interface.
    public private(set) var chosenInterface: String?

    /// Module registry.
    public var registry: ModuleRegistry

    public init(registry: ModuleRegistry = ModuleRegistry()) {
        self.registry = registry
    }

    // MARK: - Phase Flow

    /// Start a new onboarding session. Assigns a unique session ID.
    @discardableResult
    public func start() -> String {
        guard phase == .idle else { return sessionId! }
        sessionId = UUID().uuidString
        phase = .started
        return sessionId!
    }

    /// Declare the agent identity.
    public func declareAgent(_ identity: AgentIdentity) throws {
        guard phase >= .started else {
            throw OpenConstructError.notStarted
        }
        self.identity = identity
        phase = .agentDeclared
    }

    /// List available modules, optionally filtered by domain.
    public func listModules(domain: String? = nil) -> [ModuleInfo] {
        registry.listModules(domain: domain)
    }

    /// Select modules by ID.
    public func selectModules(_ ids: [String]) throws {
        guard phase >= .agentDeclared else {
            throw OpenConstructError.agentNotDeclared
        }
        // Validate all module IDs exist
        for id in ids {
            if registry.module(withId: id) == nil {
                throw OpenConstructError.moduleNotFound(id)
            }
        }
        selectedModuleIds = ids
        phase = .modulesSelected
    }

    /// Choose the interface type (e.g. "cli", "api", "embedded").
    public func chooseInterface(_ interface: String) throws {
        guard phase >= .modulesSelected else {
            throw OpenConstructError.modulesNotSelected
        }
        chosenInterface = interface
        phase = .interfaceChosen
    }

    /// Generate the final onboarding config.
    public func generateConfig() throws -> OnboardingConfig {
        guard phase >= .interfaceChosen else {
            if phase < .modulesSelected {
                throw OpenConstructError.modulesNotSelected
            }
            throw OpenConstructError.interfaceNotChosen
        }
        guard let sessionId = sessionId,
              let identity = identity,
              let chosenInterface = chosenInterface else {
            throw OpenConstructError.notStarted
        }
        let modules = selectedModuleIds.compactMap { registry.module(withId: $0) }
        phase = .configGenerated
        return OnboardingConfig(
            sessionId: sessionId,
            identity: identity,
            modules: modules,
            interface: chosenInterface
        )
    }

    // MARK: - Convenience

    /// Run the full onboarding flow in one call.
    public func onboard(
        identity: AgentIdentity,
        moduleIds: [String],
        interface: String
    ) throws -> OnboardingConfig {
        start()
        try declareAgent(identity)
        try selectModules(moduleIds)
        try chooseInterface(interface)
        return try generateConfig()
    }
}
