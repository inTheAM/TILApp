//
//  File.swift
//  
//
//  Created by Ahmed Mgua on 22/09/2021.
//

import Leaf
import Vapor

struct WebsiteController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: indexHandler)
        routes.get("acronyms", ":acronymID", use: acronymHandler)
        routes.get("users", ":userID", use: userHandler)
        routes.get("users", use: allusersHandler)
    }
    
    func indexHandler(_ req: Request) -> EventLoopFuture<View> {
        Acronym.query(on: req.db).all()
            .flatMap { acronyms in
                let contextAcronyms =  acronyms.isEmpty ? nil : acronyms
                let context = IndexContext(title: "Home", acronyms: contextAcronyms)
                return req.view.render("index", context)
            }
       
    }
    
    func acronymHandler(_ req: Request) -> EventLoopFuture<View> {
        let acronymID = req.parameters.get("acronymID", as: UUID.self)
        return Acronym.find(acronymID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { acronym in
                acronym.$user.get(on: req.db)
                    .flatMap { user in
                        let context = AcronymContext(title: acronym.short, acronym: acronym, user: user)
                        return req.view.render("acronym", context)
                    }
            }
    }
    
    func userHandler(_ req: Request) -> EventLoopFuture<View> {
        let userID = req.parameters.get("userID", as: UUID.self)
        return User.find(userID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.$acronyms.get(on: req.db)
                    .flatMap { acronyms in
                        let context = UserContext(title: user.name, user: user, acronyms: acronyms)
                        return req.view.render("user", context)
                    }
            }
    }
    func allusersHandler(_ req: Request) -> EventLoopFuture<View> {
        return User.query(on: req.db)
            .all()
            .flatMap { users  in
                let context = AllUsersContext(title: "Users", users: users)
                return req.view.render("allUsers", context)
            }
    }
}

struct IndexContext: Encodable {
    let title: String
    let acronyms: [Acronym]?
}

struct AcronymContext: Encodable {
    let title: String
    let acronym: Acronym
    let user: User
}

struct UserContext: Encodable {
    let title: String
    let user: User
    let acronyms: [Acronym]
}

struct AllUsersContext: Encodable {
    let title: String
    let users: [User]
}
