//
//  File.swift
//  File
//
//  Created by Ahmed Mgua on 02/10/2021.
//

import Fluent
import Vapor

final class Token: Model, Content {
    static var schema = "tokens"
    
    @ID
    var id: UUID?
    
    @Field(key: "value")
    var value: String
    
    @Parent(key: "userID")
    var user: User
    
    init() {}
    
    init(id: UUID? = nil, value: String, userID: User.IDValue) {
        self.id = id
        self.value = value
        self.$user.id = userID
    }
}

extension Token {
    static func generate(for user: User) throws -> Token {
        let value = [UInt8].random(count: 16).base64
        return try Token(value: value, userID: user.requireID())
    }
}

extension Token: ModelTokenAuthenticatable {
    static let valueKey = \Token.$value
    static let userKey = \Token.$user
    
    var isValid: Bool {
        true
    }
}
