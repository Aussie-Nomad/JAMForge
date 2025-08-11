//
//  Extensions.swift
//  JAMForge Profile Builder
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var jamForgeProfile: UTType {
        UTType(exportedAs: "com.jamforge.profile")
    }
}

extension Color {
    static let jamForgeOrange = Color.orange
    static let jamForgeYellow = Color.yellow
    static let jamForgeBlack = Color.black
}