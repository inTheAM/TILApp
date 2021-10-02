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

extension User {
    struct Public: Content {
        var id: UUID?
        var name: String
        var username: String
    }
    func convertToPublic() -> User.Public {
        return .init(id: id, name: name, username: username)
    }
}

extension User: Content	{
	
}

extension EventLoopFuture where Value: User {
    func convertToPublic() -> EventLoopFuture<User.Public> {
        self.map { user in
            user.convertToPublic()
        }
    }
}

extension EventLoopFuture where Value == Array<User> {
    func convertToPublic() -> EventLoopFuture<[User.Public]> {
        self.map { user in
            user.convertToPublic()
        }
    }
}

extension Collection where Element: User {
    func convertToPublic() -> [User.Public] {
        self.map { user in
            user.convertToPublic()
        }
    }
}
