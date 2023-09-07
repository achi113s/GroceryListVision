//
//  RecipeItem.swift
//  GroceryListWithVision
//
//  Created by Giorgio Latour on 8/18/23.
//

import SwiftUI

@MainActor class RecipeItems: ObservableObject {
    @Published var recipeItems: [RecipeItem]
    
    init() {
        recipeItems = [RecipeItem]()
    }
}

struct RecipeItem: Identifiable, Equatable {
    let id: UUID = UUID()
    let name: String
    var complete: Bool = false
    
    init(name: String, complete: Bool = false) {
        self.name = name
        self.complete = complete
    }
    
    static func == (lhs: RecipeItem, rhs: RecipeItem) -> Bool {
        lhs.id == rhs.id
    }
    
    mutating func toggleComplete() {
        self.complete.toggle()
    }
}
