import XCTest
@testable import Configuration

final class ConfigurationTests: XCTestCase {
 func testLabels() {
  var log = Configuration.default
  let normalDescription =
   Subject.info.categoryDescription(log, for: .debug, with: .info)

  XCTAssertEqual("[ Debug Info ]", normalDescription)

  log.uppercase = true

  let uppercaseDescription =
   Subject.info.categoryDescription(log, for: .debug, with: .info)

  XCTAssertEqual("[ DEBUG INFO ]", uppercaseDescription)

  log.lowercase = true

  let lowercaseDescription =
   Subject.info.categoryDescription(log, for: .debug, with: .info)

  XCTAssertEqual("[ debug info ]", lowercaseDescription)

  log.capitalize = true

  let singleCharacterSubcategoryDescription =
   Subject.info.categoryDescription(log, for: .function, with: "a")

  XCTAssertEqual("[ Function A ]", singleCharacterSubcategoryDescription)

  let singleCharacterCategoryDescription =
   Subject.info.categoryDescription(log, for: "a", with: .task)

  XCTAssertEqual("[ A Task ]", singleCharacterCategoryDescription)
 }
}
