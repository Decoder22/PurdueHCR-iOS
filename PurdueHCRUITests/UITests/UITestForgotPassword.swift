//
//  UITestForgotPassword.swift
//  PurdueHCRUITests
//
//  Created by Benjamin Hardin on 4/1/19.
//  Copyright © 2019 DecodeProgramming. All rights reserved.
//

import XCTest

class UITestForgotPassword: UITestBase {

	let RESIDENT_EMAIL = "UITestHonorsResident@purdue.edu"
	
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        getStartingPage().tapForgotPasswordButton()
			.typeRecoveryEmailField(email: RESIDENT_EMAIL)
    }

}
