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
        routes.get("acronyms", "create", use: createAcronymGetHandler)
        routes.post("acronyms", "create", use: createAcronymPostHandler)
        routes.get("acronyms", ":acronymID", "edit", use: editAcronymGetHandler)
        routes.post("acronyms", ":acronymID", "edit", use: editAcronymPostHandler)
        routes.post("acronyms", ":acronymID", "delete", use: deleteAcronymHandler)
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
                let userFuture = acronym.$user.get(on: req.db)
                let categoriesFuture = acronym.$categories.query(on: req.db).all()
                
                return userFuture.and(categoriesFuture)
                    .flatMap { user, categories in
                        let context = AcronymContext(title: acronym.short, acronym: acronym, user: user, categories: categories)
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
    
    func createAcronymGetHandler(_ req: Request) -> EventLoopFuture<View> {
        User.query(on: req.db)
            .all()
            .flatMap { users in
                let context = CreateAcronymContext(users: users)
                return req.view.render("createAcronym", context)
            }
    }
    
    func createAcronymPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        let data = try req.content.decode(CreateAcronymFormData.self)
        let acronym = Acronym(short: data.short, long: data.long, userID: data.userID)
        
        return acronym.save(on: req.db)
            .flatMap {
                guard let id = acronym.id else {
                    return req.eventLoop
                        .future(error: Abort(.internalServerError))
                }
                var categorySaves: [EventLoopFuture<Void>] = []
                for category in data.categories ?? [] {
                    categorySaves.append(Category.addCategory(category, to: acronym, on: req))
                }
                let redirect = req.redirect(to: "/acronyms/\(id)")
                return categorySaves.flatten(on: req.eventLoop)
                    .transform(to: redirect)
            }
    }
    
    func editAcronymGetHandler(_ req: Request) -> EventLoopFuture<View> {
        let acronymID = req.parameters.get("acronymID", as: UUID.self)
        
        let acronymFuture = Acronym.find(acronymID, on: req.db)
            .unwrap(or: Abort(.notFound))
        let userQuery = User.query(on: req.db).all()
        
        return acronymFuture.and(userQuery)
            .flatMap { acronym, users in
                acronym.$categories.get(on: req.db)
                    .flatMap { categories in
                        let context = EditAcronymContext(acronym: acronym, users: users, categories: categories)
                        return req.view.render("createAcronym", context)
                    }
            }
    }
    
    func editAcronymPostHandler(_ req: Request)  throws -> EventLoopFuture<Response> {
        let updateData = try req.content.decode(CreateAcronymFormData.self)
        let acronymID = req.parameters.get("acronymID", as: UUID.self)
        
        return Acronym.find(acronymID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { acronym in
                acronym.short = updateData.short
                acronym.long = updateData.long
                acronym.$user.id = updateData.userID
                
                guard let id = acronym.id else {
                    let error = Abort(.internalServerError)
                    return req.eventLoop.future(error: error)
                }
                let redirect = req.redirect(to: "/acronyms/\(id)")
                return acronym.save(on: req.db)
                    .flatMap {
                        acronym.$categories.get(on: req.db)
                    }.flatMap { existingCategories in
                        let existingStringArray = existingCategories.map { $0.name }
                        let existingSet = Set<String>(existingStringArray)
                        let newSet = Set<String>(updateData.categories ?? [])
                        let categoriesToAdd = newSet.subtracting(existingSet)
                        let categoriesToRemove = existingSet.subtracting(newSet)
                        
                        var categoryResults: [EventLoopFuture<Void>] = []
                        
                        for newCategory in categoriesToAdd {
                            categoryResults.append(Category.addCategory(newCategory, to: acronym, on: req))
                        }
                        for categoryToDel in categoriesToRemove {
                            if let categoryToRemove = existingCategories.first(where: { $0.name == categoryToDel }) {
                                categoryResults.append(acronym.$categories.detach(categoryToRemove, on: req.db))
                            }
                        }
                        return categoryResults.flatten(on: req.eventLoop)
                            .transform(to: redirect)
                    }
            }
    }
    
    func deleteAcronymHandler(_ req: Request) -> EventLoopFuture<Response> {
        let acronymID = req.parameters.get("acronymID", as: UUID.self)
        return Acronym.find(acronymID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { acronym in
                acronym.delete(on: req.db)
                    .transform(to: req.redirect(to: "/"))
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
        let categories: [Category]
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
    
    struct CreateAcronymContext: Encodable {
        let title = "Create an acronym"
        let users: [User]
    }
    
    struct EditAcronymContext: Encodable {
        let title = "Edit acronym"
        let acronym: Acronym
        let users: [User]
        let categories: [Category]
        let editing = true
    }
    
    struct CreateAcronymFormData: Content {
        let userID: UUID
        let short: String
        let long: String
        let categories: [String]?
    }
}
