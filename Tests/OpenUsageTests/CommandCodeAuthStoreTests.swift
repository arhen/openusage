import XCTest
@testable import OpenUsage

final class CommandCodeAuthStoreTests: XCTestCase {
    func testDetectsPiCredential() throws {
        let files = FakeFiles([
            "/home/u/.pi/agent/auth.json": #"{"commandcode": {"key": "user_abc123"}}"#
        ])
        let store = CommandCodeAuthStore(files: files, homeDirectory: { URL(fileURLWithPath: "/home/u") })
        XCTAssertTrue(store.hasPiCredential())
    }

    func testMissingFileMeansAbsent() {
        let store = CommandCodeAuthStore(
            files: FakeFiles([:]),
            homeDirectory: { URL(fileURLWithPath: "/home/u") }
        )
        XCTAssertFalse(store.hasPiCredential())
    }

    func testEmptyKeyMeansAbsent() {
        let files = FakeFiles([
            "/home/u/.pi/agent/auth.json": #"{"commandcode": {"key": "  "}}"#
        ])
        let store = CommandCodeAuthStore(files: files, homeDirectory: { URL(fileURLWithPath: "/home/u") })
        XCTAssertFalse(store.hasPiCredential())
    }

    func testPiMappingRoutesCommandCodeToOwnCard() {
        XCTAssertEqual(PiProviderMapping.cardID(forPiProvider: "commandcode"), "commandcode")
    }
}
