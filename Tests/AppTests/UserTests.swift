//
//  File.swift
//  
//
//  Created by Ahmed Mgua on 21/09/2021.
//

@testable import App
import XCTVapor

final class UserTests: XCTestCase {
	let testName = "Alice"
	let testUsername = "alice"
    let testPassword = "alice1234"
	let usersURL = "/api/users/"
	var app: Application!
	
	override func setUpWithError() throws {
		app = try Application.testable()
	}
	
	func testUserCanBeSavedWithAPI() throws {
		let user = User(name: testName, username: testUsername, password: testPassword)
		
		try app.test(.POST, usersURL, beforeRequest: { request in
			try request.content.encode(user)
		}, afterResponse: { response in
			let receivedUser = try response.content.decode(User.self)
			
			XCTAssertEqual(receivedUser.name, testName)
			XCTAssertEqual(receivedUser.username, testUsername)
			XCTAssertNotNil(receivedUser.id)
			
			try app.test(.GET, usersURL) { response in
				let users = try response.content.decode([User].self)
				XCTAssertEqual(users.count, 1)
				XCTAssertEqual(users[0].name, testName)
				XCTAssertEqual(users[0].username, testUsername)
				XCTAssertEqual(users[0].id, receivedUser.id)
			}
		})
		
		
	}
	
	func testUsersCanBeRetrievedFromAPI()	throws {
		let user = try User.create(name: testName, username: testUsername, on: app.db)
		_ = try User.create(on: app.db)

		try app.test(.GET, usersURL)	{ response in
			XCTAssertEqual(response.status, .ok)

			let users = try response.content.decode([User].self)

			XCTAssertEqual(users.count, 2)
			XCTAssertEqual(users[0].name, testName)
			XCTAssertEqual(users[0].username, testUsername)
			XCTAssertEqual(users[0].id, user.id)
		}
	}
	
	override func tearDownWithError() throws {
		app.shutdown()
	}
	
	func testGettingSingleUserFromAPI()	throws {
		let user = try User.create(name: testName, username: testUsername, on: app.db)
		
		try app.test(.GET, usersURL + "\(user.id!)") { response in
			let receivedUser = try response.content.decode(User.self)
			
			XCTAssertEqual(receivedUser.name, testName)
			XCTAssertEqual(receivedUser.username, testUsername)
			XCTAssertEqual(receivedUser.id, user.id)
			
		}
	}
	
	func testGettingUserAcronymsFromAPI() throws {
		let user = try User.create(on: app.db)
		let acronymShort = "OMG"
		let acronymLong = "Oh My God"
		
		let acronym1 = try Acronym.create(short: acronymShort, long: acronymLong, user: user, on: app.db)
		_ = try Acronym.create(short: "LOL", long: "Laugh Out Loud", user: user, on: app.db)
		try app.test(.GET, usersURL + "\(user.id!)/acronyms") { response in
			let acronyms = try response.content.decode([Acronym].self)
			
			XCTAssertEqual(acronyms.count, 2)
			XCTAssertEqual(acronyms[0].short, acronymShort)
			XCTAssertEqual(acronyms[0].long, acronymLong)
			XCTAssertEqual(acronyms[0].id, acronym1.id)
		}
	}

}
