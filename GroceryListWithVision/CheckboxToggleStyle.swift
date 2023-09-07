//
//  CheckboxToggleStyle.swift
//  GroceryListWithVision
//
//  Created by Giorgio Latour on 8/18/23.
//

import SwiftUI

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Circle()
                .stroke(style: .init(lineWidth: 2))
                .fill(.green)
                .frame(width: 25, height: 25)
                .overlay {
                    Image(systemName: configuration.isOn ? "checkmark" : "")
                        .font(.system(.body, weight: .bold))
                        .foregroundColor(.green)
                }
                .onTapGesture {
                    withAnimation() {
                        configuration.isOn.toggle()
                    }
                }
            
            configuration.label
        }
    }
}
