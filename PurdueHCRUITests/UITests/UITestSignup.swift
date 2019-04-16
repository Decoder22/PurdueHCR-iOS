//
//  UITestSignup.swift
//  PurdueHCRUITests
//
//  Created by Benjamin Hardin on 4/9/19.
//  Copyright © 2019 DecodeProgramming. All rights reserved.
//

import XCTest

class UITestSignup: UITestBase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSignupInvalidEmail() {
		let page = getStartingPage().tapCreateAccountButton()
		page.fillSignupPage(email: "InvalidEmail", name: "Example Name", password: "validpassword", code: "4N123").waitForDropDownNotification(message: "Failed to Sign Up")
    }

	func testSignupInvalidName() {
		let page = getStartingPage().tapCreateAccountButton()
		page.fillSignupPage(email: "validemail@purdue.edu", name: "InvalidName", password: "validpassword", code: "4N123").waitForDropDownNotification(message: "Failed to Sign Up")
	}
	
	func testSignupInvalidPassword() {
		let page = getStartingPage().tapCreateAccountButton()
		page.fillSignupPage(email: "validemail@purdue.edu", name: "Valid Name", password: "invalid password", code: "4N123").waitForDropDownNotification(message: "Failed to Sign Up")
	}
	
	func testSignupInvalidCode() {
		let page = getStartingPage().tapCreateAccountButton()
		page.fillSignupPage(email: "validemail@purdue.edu", name: "Valid Name", password: "validpassword", code: "invalidcode").waitForDropDownNotification(message: "Failed to Sign Up")
	}
	
	func testAlreadySignedUp() {
		let page = getStartingPage().tapCreateAccountButton()
		page.fillSignupPage(email: "tester@purdue.edu", name: "Valid Name", password: "validpassword", code: "4N123").waitForDropDownNotification(message: "Failed to Sign Up")
	}
	
}
