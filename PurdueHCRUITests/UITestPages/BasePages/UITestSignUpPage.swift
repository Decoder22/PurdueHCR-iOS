//
//  UITestSignUpPage.swift
//  PurdueHCRUITests
//
//  Created by Brian Johncox on 3/27/19.
//  Copyright © 2019 DecodeProgramming. All rights reserved.
//

import Foundation

import XCTest

class SignUpPage: BasePage, UITestPageProtocol {
    
    let emailField:XCUIElement
    let nameField:XCUIElement
    let passwordField:XCUIElement
    let verifyPasswordField:XCUIElement
    let codeField:XCUIElement
    let signupButton:XCUIElement
    let returnToSignInButton:XCUIElement
    
    override init(app: XCUIApplication, test: XCTestCase) {
        emailField = app.textFields["Email"]
        nameField = app.textFields["Name"]
        passwordField = app.secureTextFields["Password"]
        verifyPasswordField = app.secureTextFields["Verify Password"]
        codeField = app.textFields["Code"]
        signupButton = app.buttons["Sign up"]
        returnToSignInButton = app.buttons["Go back to Log In"]
        super.init(app: app, test: test)
    }
    
    @discardableResult func waitForLoadingToComplete() -> SignUpPage {
        waitForLoading()
        return self
    }
    
    @discardableResult
    func typeEmail(email:String) -> SignUpPage {
        emailField.tap()
		clearTextField(textField: emailField)
        emailField.typeText(email)
        return self
    }
    
    @discardableResult
    func typeName(name:String) -> SignUpPage {
        nameField.tap()
		clearTextField(textField: nameField)
        nameField.typeText(name)
        return self
    }
    
    @discardableResult
    func typePassword(password:String) -> SignUpPage {
        passwordField.tap()
		clearTextField(textField: passwordField)
        passwordField.typeText(password)
        return self
    }
    
    @discardableResult
    func typeVerifyPassword(password:String) -> SignUpPage {
        verifyPasswordField.tap()
		clearTextField(textField: verifyPasswordField)
        verifyPasswordField.typeText(password)
        return self
    }
    
    @discardableResult
    func typeCode(code:String) -> SignUpPage {
        codeField.tap()
		/*for _ in 1...(codeField.value as! String).count {
			app.keys["delete"].tap()
		}*/
		clearTextField(textField: codeField)
        codeField.typeText(code)
        return self
    }
    
    @discardableResult
    func tapSignupButton() -> ProfilePage {
        signupButton.tap()
        return ProfilePage(app: app,test: test)
    }
    
    @discardableResult
    func tapReturnToSignInPage() -> SignInPage {
        returnToSignInButton.tap()
        return SignInPage(app: app,test: test)
    }
    
    @discardableResult
	func fillSignupPage(email:String, name:String, password:String, verifyPassword:String = "", code:String) -> ProfilePage {
		return typeEmail(email: email).typeName(name: name).typePassword(password: password).typeVerifyPassword(password: (verifyPassword == "") ? password : verifyPassword).typeCode(code: code).tapSignupButton()
    }
    
}
