//
//  File.swift
//  
//
//  Created by Ahmed Mgua on 19/09/2021.
//

import Fluent
import Vapor

struct AcronymsController: RouteCollection {
	func boot(routes: RoutesBuilder) throws {
		let acronymsRoutes = routes.grouped("api", "acronyms")
		
		acronymsRoutes.get(use: getAllHandler)
		acronymsRoutes.post(use: createHandler)
		acronymsRoutes.get(":acronymID", use: getHandler)
		acronymsRoutes.put(":acronymID", use: updateHandler)
		acronymsRoutes.get("search", use: searchHandler)
		acronymsRoutes.get("first", use: getFirstHandler)
		acronymsRoutes.get("last", use: getLastHandler)
		acronymsRoutes.get("sorted", use: getSortedHandler)
	}
	
	func getAllHandler(_ req: Request) -> EventLoopFuture<[Acronym]>	{
		return Acronym.query(on: req.db).all()
	}
	
	func createHandler(_ req: Request) throws -> EventLoopFuture<Acronym> {
		let acronym = try req.content.decode(Acronym.self)
		return acronym.save(on: req.db)
			.map {
				acronym
			}
	}
	
	func getHandler(_ req: Request) -> EventLoopFuture<Acronym> {
		let acronymID = req.parameters.get("acronymID", as: UUID.self)
		return Acronym.find(acronymID, on: req.db)
			.unwrap(or: Abort(.notFound))
	}
	
	func updateHandler(_ req: Request) throws -> EventLoopFuture<Acronym> {
		let updatedAcronym = try req.content.decode(Acronym.self)
		let acronymID = req.parameters.get("acronymID", as: UUID.self)
		return Acronym.find(acronymID, on: req.db)
			.unwrap(or: Abort(.notFound))
			.flatMap { acronym in
				acronym.short = updatedAcronym.short
				acronym.long = updatedAcronym.long
				return acronym
					.save(on: req.db)
					.map {
						acronym
					}
			}
	}
	
	func deleteHandler(_ req: Request) -> EventLoopFuture<HTTPStatus> {
		let acronymID = req.parameters.get("acronymID", as: UUID.self)
		return Acronym.find(acronymID, on: req.db)
			.unwrap(or: Abort(.notFound))
			.flatMap { acronym in
				acronym.delete(on: req.db)
			}
			.transform(to: .noContent)
	}
	
	func searchHandler(_ req: Request) throws -> EventLoopFuture<[Acronym]> {
		guard let searchTerm = req.query[String.self, at: "term"] else {
			throw Abort(.badRequest)
		}
		
//		return Acronym.query(on: req.db)
//			.filter(\.$short == searchTerm)
//			.all()
		return Acronym.query(on: req.db)
			.group(.or) { or in
				or.filter(\.$short == searchTerm)
				or.filter(\.$long == searchTerm)
			}
			.all()
	}
	
	
	func getFirstHandler(_ req: Request) -> EventLoopFuture<Acronym> {
		return Acronym.query(on: req.db)
			.first()
			.unwrap(or: Abort(.notFound))
	}
	
	func getLastHandler(_ req: Request) -> EventLoopFuture<Acronym> {
		return Acronym.query(on: req.db)
			.all()
			.flatMapThrowing { acronyms in
				guard let last = acronyms.last else {
					throw Abort(.notFound)
				}
				return last
			}
	}
	
	func getSortedHandler(_ req: Request) -> EventLoopFuture<[Acronym]> {
		return Acronym.query(on: req.db)
			.sort(\.$short, .ascending)
			.all()
	}
}
