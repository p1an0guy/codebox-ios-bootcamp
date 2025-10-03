//
//  ios_bootcampApp.swift
//  ios-bootcamp
//
//  Created by Jonah Chan on 10/3/25.
//

import SwiftUI
import Supabase

@main
struct ios_bootcampApp: App {
    let client = SupabaseClient(
        supabaseURL: URL(string: "https://shxpiezclobqmeiwzupt.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNoeHBpZXpjbG9icW1laXd6dXB0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk0OTM2NTAsImV4cCI6MjA3NTA2OTY1MH0.nv1m6BJOvbV1GXKL9agGDWd151EAnLHh1JSuKiGWXhw"
    )

    var body: some Scene {
        WindowGroup {
            ContentView(client: client)  // 👈 inject client here
        }
    }
}
