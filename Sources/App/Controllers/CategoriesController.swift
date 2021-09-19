//
//  File.swift
//  
//
//  Created by Ahmed Mgua on 19/09/2021.
//

import Vapor

struct CategoriesController: RouteCollection	{
	func boot(routes: RoutesBuilder) throws {
		let categoriesRoute = routes.grouped("api", "categories")
		
		categoriesRoute.post(use: createHandler)
		categoriesRoute.get(use: getAllHandler)
		categoriesRoute.get(":categoryID", use: getHandler)
	}
	
	func createHandler(_ req: Request) throws -> EventLoopFuture<Category> {
		let category = try req.content.decode(Category.self)
		return category.save(on: req.db)
			.map {
				category
			}
	}
	
	func getAllHandler(_ req: Request) -> EventLoopFuture<[Category]> {
		return Category.query(on: req.db).all()
	}
	
	func getHandler(_ req: Request) -> EventLoopFuture<Category> {
		let categoryID = req.parameters.get("categoryID", as: UUID.self)
		return Category.find(categoryID, on: req.db)
			.unwrap(or: Abort(.notFound))
	}
}
