import XCTest
@testable import OpenConstruct

final class OpenConstructTests: XCTestCase {

    // MARK: - Helpers

    private func makeRegistry() -> ModuleRegistry {
        var registry = ModuleRegistry()
        registry.register(ModuleInfo(id: "spectral-graph-core", name: "Spectral Graph Core", domain: "math"))
        registry.register(ModuleInfo(id: "plato-room", name: "Plato Room", domain: "math"))
        registry.register(ModuleInfo(id: "nlp-toolkit", name: "NLP Toolkit", domain: "language"))
        registry.register(ModuleInfo(id: "vision-pro", name: "Vision Pro", domain: "vision"))
        return registry
    }

    // MARK: - Tests

    func testStartAssignsSessionId() {
        let client = OpenConstructClient()
        let sid = client.start()
        XCTAssertFalse(sid.isEmpty)
        XCTAssertEqual(client.phase, .started)
        XCTAssertEqual(client.sessionId, sid)
    }

    func testStartGeneratesUniqueSessionIds() {
        let a = OpenConstructClient()
        let b = OpenConstructClient()
        a.start()
        b.start()
        XCTAssertNotEqual(a.sessionId, b.sessionId)
    }

    func testDeclareAgent() throws {
        let client = OpenConstructClient()
        client.start()
        let identity = AgentIdentity(name: "my-agent", model: "glm-5.1", capabilities: ["code_generation"])
        try client.declareAgent(identity)
        XCTAssertEqual(client.phase, .agentDeclared)
        XCTAssertEqual(client.identity, identity)
    }

    func testDeclareAgentBeforeStartThrows() {
        let client = OpenConstructClient()
        let identity = AgentIdentity(name: "early-agent", model: "glm-5.1")
        XCTAssertThrowsError(try client.declareAgent(identity)) { error in
            XCTAssertEqual(error as? OpenConstructError, .notStarted)
        }
    }

    func testListModulesReturnsAll() {
        let registry = makeRegistry()
        let client = OpenConstructClient(registry: registry)
        let all = client.listModules()
        XCTAssertEqual(all.count, 4)
    }

    func testListModulesFiltersByDomain() {
        let registry = makeRegistry()
        let client = OpenConstructClient(registry: registry)
        let mathModules = client.listModules(domain: "math")
        XCTAssertEqual(mathModules.count, 2)
        XCTAssertTrue(mathModules.allSatisfy { $0.domain == "math" })
    }

    func testSelectModules() throws {
        let registry = makeRegistry()
        let client = OpenConstructClient(registry: registry)
        client.start()
        try client.declareAgent(AgentIdentity(name: "a", model: "m"))
        try client.selectModules(["spectral-graph-core", "plato-room"])
        XCTAssertEqual(client.phase, .modulesSelected)
        XCTAssertEqual(client.selectedModuleIds, ["spectral-graph-core", "plato-room"])
    }

    func testSelectModulesThrowsForUnknownId() throws {
        let registry = makeRegistry()
        let client = OpenConstructClient(registry: registry)
        client.start()
        try client.declareAgent(AgentIdentity(name: "a", model: "m"))
        XCTAssertThrowsError(try client.selectModules(["nonexistent"])) { error in
            XCTAssertEqual(error as? OpenConstructError, .moduleNotFound("nonexistent"))
        }
    }

    func testChooseInterface() throws {
        let client = OpenConstructClient(registry: makeRegistry())
        client.start()
        try client.declareAgent(AgentIdentity(name: "a", model: "m"))
        try client.selectModules(["spectral-graph-core"])
        try client.chooseInterface("cli")
        XCTAssertEqual(client.phase, .interfaceChosen)
        XCTAssertEqual(client.chosenInterface, "cli")
    }

    func testGenerateConfig() throws {
        let client = OpenConstructClient(registry: makeRegistry())
        client.start()
        let identity = AgentIdentity(name: "test-agent", model: "glm-5.1", capabilities: ["code_generation"])
        try client.declareAgent(identity)
        try client.selectModules(["spectral-graph-core", "plato-room"])
        try client.chooseInterface("api")
        let config = try client.generateConfig()

        XCTAssertEqual(client.phase, .configGenerated)
        XCTAssertEqual(config.identity, identity)
        XCTAssertEqual(config.modules.count, 2)
        XCTAssertEqual(config.interface, "api")
        XCTAssertFalse(config.sessionId.isEmpty)
    }

    func testGenerateConfigThrowsIfInterfaceNotChosen() throws {
        let client = OpenConstructClient(registry: makeRegistry())
        client.start()
        try client.declareAgent(AgentIdentity(name: "a", model: "m"))
        try client.selectModules(["spectral-graph-core"])
        XCTAssertThrowsError(try client.generateConfig()) { error in
            XCTAssertEqual(error as? OpenConstructError, .interfaceNotChosen)
        }
    }

    func testFullLifecycle() throws {
        let client = OpenConstructClient(registry: makeRegistry())
        let config = try client.onboard(
            identity: AgentIdentity(name: "lifecycle-agent", model: "glm-5.1"),
            moduleIds: ["nlp-toolkit", "vision-pro"],
            interface: "embedded"
        )
        XCTAssertEqual(config.identity.name, "lifecycle-agent")
        XCTAssertEqual(config.modules.count, 2)
        XCTAssertEqual(config.interface, "embedded")
        XCTAssertEqual(client.phase, .configGenerated)
    }
}
