//
//  AsyncValueUITest.swift
//  AsyncValueTestAppUITests
//
//  Created by Brent Mifsud on 2022-09-02.
//

import XCTest

class AsyncValueUITest: XCTestCase {
    var app: XCUIApplication?
    
    lazy var observedObjectText: XCUIElement = {
        app!/*@START_MENU_TOKEN@*/.staticTexts["observed-object-value"]/*[[".staticTexts[\"ObservableObject: Test\"]",".staticTexts[\"observed-object-value\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
    }()
    
    lazy var onChangeText: XCUIElement = {
        app!/*@START_MENU_TOKEN@*/.staticTexts["on-change-value"]/*[[".staticTexts[\".onChange: Test\"]",".staticTexts[\"on-change-value\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
    }()
    
    lazy var changeValueButton: XCUIElement = {
        app!.buttons["change-value"]
    }()
    
    lazy var resetValueButton: XCUIElement = {
        app!.buttons["reset-value"]
    }()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        if app == nil {
            app = XCUIApplication()
            app?.launch()
        }
    }

    func test_asyncValue_works_with_observableObject() throws {
        XCTAssertEqual(observedObjectText.label, "ObservableObject: Test")
        changeValueButton.tap()
        XCTAssertEqual(observedObjectText.label, "ObservableObject: Updated Value")
    }
    
    func test_asyncValue_asyncSequence_works() throws {
        XCTAssertEqual(onChangeText.label, ".onChange: Test")
        changeValueButton.tap()
        XCTAssertEqual(onChangeText.label, ".onChange: Updated Value")
    }
    
    override func tearDownWithError() throws {
        resetValueButton.tap()
    }
}
