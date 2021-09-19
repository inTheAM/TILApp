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
	
	init()	{}
	
	init(id: UUID? = nil, name: String)	{
		self.id = id
		self.name = name
	}
}

extension Category: Content {
	
}
