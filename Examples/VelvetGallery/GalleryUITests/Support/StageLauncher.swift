import XCTest

/// Launches the VelvetGallery straight into one recording stage, the same way
/// `-VelvetStage <ID>` does for screen recording, so a UI test starts on the
/// component with no navigation.
enum StageLauncher {
    enum Scheme: String, CaseIterable {
        case light, dark
    }

    /// Launches `stage` in `scheme` with autoplay off and waits until the stage
    /// is on screen. Fails the test if it never appears.
    @MainActor
    @discardableResult
    static func launch(
        _ stage: String,
        scheme: Scheme = .light,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-VelvetStage", stage,
            "-VelvetAppearance", scheme.rawValue,
            "-VelvetStageAutoplay", "NO",
            "-VelvetStageBackground", "neutral",
        ]
        app.launch()

        let root = app.otherElements["stage.\(stage)"]
        XCTAssertTrue(
            root.waitForExistence(timeout: 15),
            "Stage \(stage) (\(scheme.rawValue)) never appeared.",
            file: file, line: line
        )
        return app
    }

    /// Lets springs and entrance animations settle before asserting or capturing.
    static func settle(_ seconds: TimeInterval = 1.0) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    /// Attaches a screenshot to the test result. CI exports these as an artifact,
    /// so every PR comes with a picture of each stage in light and dark.
    @MainActor
    static func attachScreenshot(_ app: XCUIApplication, named name: String, to testCase: XCTestCase) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        testCase.add(attachment)
    }
}

extension XCUIApplication {
    /// The first element with this accessibility label or identifier, of any type.
    /// SwiftUI controls with the toggle trait can surface as buttons, switches or
    /// toggles depending on the OS, so tests look them up by label, not by type.
    func element(_ labelOrIdentifier: String) -> XCUIElement {
        descendants(matching: .any)[labelOrIdentifier].firstMatch
    }
}

extension XCUIElement {
    /// The accessibility value as a string ("On", "Liked, 129", …).
    var stringValue: String? { value as? String }

    /// Waits until the accessibility value equals `expected`.
    func waitForValue(_ expected: String, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "value == %@", expected)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
