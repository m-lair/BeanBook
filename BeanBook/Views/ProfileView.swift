//
//  MainView.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/22/25.
//
import SwiftUI

struct ProfileView: View {
    @Environment(AuthManager.self) var authManager
    @Environment(CoffeeBrewManager.self) var brewManager
    
    @State private var showNewBrew = false
    
    var body: some View {
        NavigationStack {
            if let user = authManager.user {
                List(brewManager.userBrews) { brew in
                    NavigationLink {
                        BrewDetailView(brew: brew)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(brew.title)
                            Text(brew.method)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .navigationTitle("My Brews")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Sign Out") {
                            
                            authManager.signOut()
                            
                            
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showNewBrew = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showNewBrew) {
                    NewBrewView()
                }
                .task {
                    await brewManager.fetchUserBrews(for: user.uid)
                }
            } else {
                Text("No user is currently logged in.")
            }
        }
    }
}

#Preview {
    ProfileView()
        .environment(AuthManager())
}
