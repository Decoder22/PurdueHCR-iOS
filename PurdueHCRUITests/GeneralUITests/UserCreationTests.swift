//
//  UserCreationTests.swift
//  PurdueHCRUITests
//
//  Created by Benjamin Hardin on 3/25/19.
//  Copyright © 2019 DecodeProgramming. All rights reserved.
//

import XCTest

class UserCreationTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testUserCreation() {
        // Test that a user is able to be created.
		let app = XCUIApplication()
		app.launch()
		UITestUtils.waitForLoadingToComplete(app: app, test: self)
		UITestUtils.logout(app: app)
		
		// Test when there is an invalid email
		app.buttons["Want to create an account?"].tap()
		let emailTextField = app/*@START_MENU_TOKEN@*/.textFields["Email"]/*[[".scrollViews.textFields[\"Email\"]",".textFields[\"Email\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
		emailTextField.tap()
		emailTextField.typeText("BogusEmail")
		let nameTextField = app/*@START_MENU_TOKEN@*/.textFields["Name"]/*[[".scrollViews.textFields[\"Name\"]",".textFields[\"Name\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
		nameTextField.tap()
		nameTextField.typeText("TestName")
		let passwordTextField = app/*@START_MENU_TOKEN@*/.secureTextFields["Password"]/*[[".scrollViews.secureTextFields[\"Password\"]",".secureTextFields[\"Password\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
		passwordTextField.tap()
		passwordTextField.typeText("TestPassword")
		let verifyPasswordSecureTextField = app/*@START_MENU_TOKEN@*/.secureTextFields["Verify Password"]/*[[".scrollViews.secureTextFields[\"Verify Password\"]",".secureTextFields[\"Verify Password\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
		verifyPasswordSecureTextField.tap()
		verifyPasswordSecureTextField.typeText("TestPassword")
		let codeTextField = app/*@START_MENU_TOKEN@*/.textFields["Code"]/*[[".scrollViews.textFields[\"Code\"]",".textFields[\"Code\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
		codeTextField.tap()
		codeTextField.typeText("4N123")
		app/*@START_MENU_TOKEN@*/.buttons["Sign up"]/*[[".scrollViews.buttons[\"Sign up\"]",".buttons[\"Sign up\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
		
		// Test when there is an invalid name
		
		// Test when there is an invalid password
		
		// Test when there is an inconsistent password
		
		// Test when there is an invalid floor code
		
    }

}
