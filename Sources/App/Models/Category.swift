//
//  File.swift
//  
//
//  Created by Ahmed Mgua on 19/09/2021.
//

import Fluent
import Vapor

final class Category: Model	{
	static var schema = "categories"
	
	@ID
	var id: UUID?
	
	@Field(key: "name")
	var name: String
	
	@Siblings(through: AcronymCategoryPivot.self, from: \.$category, to: \.$acronym)
	var acronyms: [Acronym]
	
	init()	{}
	
	init(id: UUID? = nil, name: String)	{
		self.id = id
		self.name = name
	}
}

extension Category: Content {
	
}

extension Category {
    static func addCategory(_ name: String, to acronym: Acronym, on req: Request) -> EventLoopFuture<Void> {
        return Category.query(on: req.db)
            .filter(\.$name == name)
            .first()
            .flatMap { foundCategory in
                if let foundCategory = foundCategory {
                    return acronym.$categories.attach(foundCategory, on: req.db)
                } else {
                    let newCategory = Category(name: name)
                    return newCategory.save(on: req.db)
                        .flatMap {
                            acronym.$categories.attach(newCategory, on: req.db)
                        }
                }
            }
    }
}
