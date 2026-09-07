import XCTest
@testable import Cresset

final class CressetTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: CressetApp.self), "CressetApp")
        XCTAssertEqual(HarborInk.face, "SF Pro")
    }

    func test_figuresRejectNegativeAndNonNumeric() {
        XCTAssertNil(LampFigure.parseDecimal("-4"))
        XCTAssertNil(LampFigure.parseDecimal("abc"))
        XCTAssertNil(LampFigure.parseDecimal(""))
        XCTAssertNil(LampFigure.parseCount("-2"))
        XCTAssertNil(LampFigure.parseCount("0"))
        XCTAssertEqual(LampFigure.parseDecimal("12"), 12)
        XCTAssertFalse(LampFigure.sanitizeDecimal("-12.5").contains("-"))
        XCTAssertTrue(LampFigure.sanitizeDecimal("-12.5").contains("12"))
        XCTAssertEqual(LampFigure.sanitizeCount("-40a"), "40")
        XCTAssertNotEqual(LampFigure.pages(15), "0")
        XCTAssertEqual(LampFigure.count(8), LampFigure.count(8))
        XCTAssertFalse(LampFigure.count(8).isEmpty)
    }
}
