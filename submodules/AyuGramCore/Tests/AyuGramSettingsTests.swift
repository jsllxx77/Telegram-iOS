import XCTest
import AyuGramCore

final class AyuGramSettingsTests: XCTestCase {
    func testLiquidGlassStyleDefaultsToSystem() throws {
        let data = try JSONEncoder().encode([String: Int]())
        let settings = try JSONDecoder().decode(AyuGramSettings.self, from: data)

        XCTAssertEqual(settings.liquidGlassStyle, .system)
    }

    func testLiquidGlassStyleRoundTrips() throws {
        let settings = AyuGramSettings(liquidGlassStyle: .compatibility)
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(AyuGramSettings.self, from: data)

        XCTAssertEqual(decoded.liquidGlassStyle, .compatibility)
    }
}
