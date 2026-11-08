//
//  GiffyApp.swift
//  Giffy
//
//  Created by Mikita Halitski on 25/10/2026.
//

import SwiftUI

@main
struct GiffyApp: App {
    @State private var converterModel = ConverterModel()
    @State private var isMenuBarInserted = true // M8 replaces with AppSettings

    var body: some Scene {
        Window("Giffy", id: "main") {
            MainView(converterModel: converterModel)
        }

        MenuBarExtra("Giffy", image: "MenuBarIcon", isInserted: $isMenuBarInserted) {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}
