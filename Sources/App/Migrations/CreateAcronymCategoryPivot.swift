//
//  File.swift
//  
//
//  Created by Ahmed Mgua on 21/09/2021.
//

import Fluent

final class CreateAcronymCategoryPivot: Migration	{
	func prepare(on database: Database) -> EventLoopFuture<Void> {
		database.schema("acronym-category-pivot")
			.id()
			.field("acronymID", .uuid, .required, .references("acronyms", "id", onDelete: .cascade))
			.field("categoryID", .uuid, .required, .references("categories", "id", onDelete: .cascade))
			.create()
	}
	
	func revert(on database: Database) -> EventLoopFuture<Void> {
		database.schema("acronym-category-pivot")
			.delete()
	}
}
