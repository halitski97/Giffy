//
//  GiffyApp.swift
//  Giffy
//
//  Created by Mikita Halitski on 25/10/2026.
//

import SwiftUI

@main
struct GiffyApp: App {
    @State private var environment: AppEnvironment
    @State private var converterModel: ConverterModel
    @State private var isMenuBarInserted = true // M8 replaces with AppSettings

    init() {
        let environment = AppEnvironment()
        _environment = State(initialValue: environment)
        _converterModel = State(initialValue: ConverterModel(sourceLoader: environment.sourceLoader))
    }

    var body: some Scene {
        Window("Giffy", id: "main") {
            MainView(converterModel: converterModel)
        }
        .environment(environment)

        MenuBarExtra("Giffy", image: "MenuBarIcon", isInserted: $isMenuBarInserted) {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}
