//
//  ProgressView.swift
//  GroceryListWithVision
//
//  Created by Giorgio Latour on 8/19/23.
//

import SwiftUI

struct ProgressView: View {
    let progressIndicator: [String] = ["", ".", "..", "..."]
    @State private var curr: Int = 0
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .foregroundColor(.white)
                .frame(width: 250, height: 150)
                .shadow(color: Color.init(white: 0.8), radius: 10)
            HStack(spacing: 1) {
                Text("Processing Image")
                    .font(.body)
                Text("\(progressIndicator[curr])")
                    .onReceive(timer) { input in
                        if curr < progressIndicator.count - 1 {
                            curr += 1
                        } else {
                            curr = 0
                        }
                    }
            }
        }
        .onDisappear {
            self.timer.upstream.connect().cancel()
        }
    }
}

struct ProgressView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressView()
    }
}
