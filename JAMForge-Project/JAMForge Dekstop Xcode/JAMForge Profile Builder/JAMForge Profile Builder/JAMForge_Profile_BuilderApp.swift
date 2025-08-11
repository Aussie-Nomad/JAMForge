//
//  JAMForge_Profile_BuilderApp.swift
//  JAMForge Profile Builder
//
//  Created by JAMForge on $(date +%m/%d/%y).
//

import SwiftUI

@main
struct JAMForge_Profile_BuilderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1200, minHeight: 800)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
    }
}
