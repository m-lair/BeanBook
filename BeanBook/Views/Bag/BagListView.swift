//
//  BagListView.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/25/25.
//
import SwiftUI
struct BagListView: View {
    @Environment(CoffeeBagManager.self) var bagManager
    @Environment(CoffeeBrewManager.self) var brewManager
    @Environment(UserManager.self) var userManager
    
    var body: some View {
        List(bagManager.bags) { bag in
            BagCollapsibleView(bag: bag)
                .environment(brewManager)
                .environment(userManager)
        }
        .task {
            await bagManager.fetchCoffeeBags()
        }
        
    }
}

// 2) New Collapsible View Component
struct BagCollapsibleView: View {
    let bag: CoffeeBag
    @Environment(CoffeeBrewManager.self) private var brewManager
    @Environment(UserManager.self) private var userManager
    
    @State private var isExpanded = false
    @State private var associatedBrews: [CoffeeBrew] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if let errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundStyle(.red)
                } else if associatedBrews.isEmpty {
                    Text("No brews recorded for this bag")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(associatedBrews) { brew in
                        BrewRowView(brew: brew)
                    }
                }
            }
            .padding(.leading, 16)
            
        } label: {
            BagRowView(bag: bag)
        }
        .onChange(of: isExpanded) {
            if isExpanded && associatedBrews.isEmpty {
                loadAssociatedBrews()
            }
        }
    }
    
    private func loadAssociatedBrews() {
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                guard let userId = userManager.currentUID else {
                    throw NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                }
                
                associatedBrews = try await brewManager.fetchBrewsForBag(
                    bagId: bag.id ?? "",
                    userId: userId
                )
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isLoading = false
        }
    }
}

private struct BagRowView: View {
    let bag: CoffeeBag
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(bag.brandName).font(.headline)
                Text("\(bag.roastLevel) roast from \(bag.origin)")
                    .font(.subheadline)
            }
            Spacer()
            if let bagImage = bag.imageURL {
                AsyncImage(url: URL(string: bagImage)) { image in
                    image
                        .resizable()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(Color.brown.opacity(0.3))
                        .frame(width: 50, height: 50)
                }
            }
        }
    }
}

private struct BrewRowView: View {
    let brew: CoffeeBrew
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(brew.title)
                    .font(.subheadline)
                Spacer()
                Text(brew.method)
                    .foregroundStyle(.secondary)
            }
            
            Text(brew.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}
