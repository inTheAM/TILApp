//
//  File.swift
//  
//
//  Created by Ahmed Mgua on 19/09/2021.
//

import Fluent
import Vapor

final class User: Model	{
	static let schema = "users"
	
	@ID
	var id: UUID?
	
	@Field(key: "name")
	var name: String
	
	@Field(key: "username")
	var username: String
    
    @Field(key: "password")
    var password: String
	
	@Children(for: \.$user)
	var acronyms: [Acronym]
	
	init() {}
	
    init(id: UUID? = nil, name: String, username: String, password: String)	{
		self.name = name
		self.username = username
        self.password = password
	}
}

extension User: Content	{
	
}
