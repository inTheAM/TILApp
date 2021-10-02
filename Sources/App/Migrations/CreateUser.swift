//
//  File.swift
//  
//
//  Created by Ahmed Mgua on 19/09/2021.
//

import Fluent

struct CreateUser:	Migration	{
	func prepare(on database: Database) -> EventLoopFuture<Void> {
		database.schema("users")
			.id()
			.field("name", .string, .required)
			.field("username", .string,	.required)
            .field("password", .string, .required)
            .unique(on: "username")
			.create()
	}
	
	func revert(on database: Database) -> EventLoopFuture<Void> {
		database.schema("users")
			.delete()
	}
}
