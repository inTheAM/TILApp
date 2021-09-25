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
        routes.get("categories", use: allCategoriesHandler)
        routes.get("categories", ":categoryID", use: categoryHandler)
    }
    
    func indexHandler(_ req: Request) -> EventLoopFuture<View> {
        Acronym.query(on: req.db).all()
            .flatMap { acronyms in
                let context = IndexContext(title: "Home", acronyms: acronyms)
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
    
    func allCategoriesHandler(_ req: Request) -> EventLoopFuture<View> {
        return Category.query(on: req.db)
            .all()
            .flatMap { categories in
                let context = AllCategoriesContext(categories: categories)
                return req.view.render("allCategories", context)
            }
    }
    
    func categoryHandler(_ req: Request) -> EventLoopFuture<View> {
        let categoryID = req.parameters.get("categoryID", as: UUID.self)
        return Category.find(categoryID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { category in
                category.$acronyms.get(on: req.db)
                    .flatMap { acronyms in
                        let context = CategoryContext(title: category.name, category: category, acronyms: acronyms)
                        return req.view.render("category", context)
                    }
            }
    }
}

extension WebsiteController {
    struct IndexContext: Encodable {
        let title: String
        let acronyms: [Acronym]
    }
    
    struct AcronymContext: Encodable {
        let title: String
        let acronym: Acronym
        let user: User
    }
    
    struct CategoryContext: Encodable {
        let title: String
        let category: Category
        let acronyms: [Acronym]
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
    
    struct AllCategoriesContext: Encodable {
        let title = "All Categories"
        let categories: [Category]
    }
    
}
