//
//  File.swift
//  
//
//  Created by Ahmed Mgua on 19/09/2021.
//

import Vapor

struct UsersController: RouteCollection	{
	func boot(routes: RoutesBuilder) throws {
		let usersRoute = routes.grouped("api", "users")
		
		usersRoute.post(use: createHandler)
		usersRoute.get(use: getAllHandler)
		usersRoute.get(":userID", use: getHandler)
	}
	
	func createHandler(_ req:	Request) throws ->	EventLoopFuture<User> {
		let user = try req.content.decode(User.self)
		
		return user.save(on: req.db)
			.map {
				user
			}
	}
	
	func getAllHandler(_ req: Request) -> EventLoopFuture<[User]> {
		return User.query(on: req.db).all()
	}
	
	func getHandler(_ req: Request) -> EventLoopFuture<User> {
		let userID = req.parameters.get("userID", as: UUID.self)
		return User.find(userID, on: req.db)
			.unwrap(or: Abort(.notFound))
	}
}
