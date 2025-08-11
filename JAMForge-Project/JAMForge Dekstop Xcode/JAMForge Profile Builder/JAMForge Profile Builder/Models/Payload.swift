//
//  Payload.swift
//  JAMForge Profile Builder
//
//  Created by JAMForge on $(date +%m/%d/%y).
//

import Foundation

struct Payload: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let platforms: [String]
    let icon: String
    let category: String
    var enabled: Bool = true
    let uuid: String
    
    init(id: String, name: String, description: String, platforms: [String], icon: String, category: String) {
        self.id = id
        self.name = name
        self.description = description
        self.platforms = platforms
        self.icon = icon
        self.category = category
        self.uuid = UUID().uuidString
    }
    
    // Codable conformance
    enum CodingKeys: CodingKey {
        case id, name, description, platforms, icon, category, enabled, uuid
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        platforms = try container.decode([String].self, forKey: .platforms)
        icon = try container.decode(String.self, forKey: .icon)
        category = try container.decode(String.self, forKey: .category)
        enabled = try container.decode(Bool.self, forKey: .enabled)
        uuid = try container.decode(String.self, forKey: .uuid)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(platforms, forKey: .platforms)
        try container.encode(icon, forKey: .icon)
        try container.encode(category, forKey: .category)
        try container.encode(enabled, forKey: .enabled)
        try container.encode(uuid, forKey: .uuid)
    }
}

struct ProfileSettings {
    var name: String = "New Configuration Profile"
    var description: String = "Created with JAMForge Profile Builder"
    var identifier: String = "com.jamforge.profile.\(Int(Date().timeIntervalSince1970))"
    var organization: String = "Your Organization"
    var scope: String = "System"
}

struct ProfileTemplate {
    let name: String
    let description: String
    let payloadIds: [String]
}