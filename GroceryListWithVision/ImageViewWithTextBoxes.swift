//
//  ImageViewWithTextBoxes.swift
//  GroceryListWithVision
//
//  Created by Giorgio Latour on 8/17/23.
//

import SwiftUI
import Vision

struct ImageViewWithTextBoxes: View {
    var image: UIImage
    var textBoundingBoxes: [CGRect]
    
    var body: some View {
        VStack {
            Image(uiImage: self.image)
                .resizable()
                .scaledToFit()
                .overlay {
                    GeometryReader { geo in
                        ZStack {
                            ForEach(0...(textBoundingBoxes.count - 1), id: \.self) { index in
                                let rect = VNImageRectForNormalizedRect(textBoundingBoxes[index], Int(geo.size.width), Int(geo.size.height))
                                Rectangle()
                                    .fill(.blue.opacity(0.5))
                                    .frame(width: rect.width, height: rect.height)
                                    .position(x: rect.origin.x + rect.width/2, y: rect.origin.y + rect.height/2)
                            }
                        }
                        //Geometry reader makes the view shrink to its smallest size
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        //Flip upside down
                        .rotation3DEffect(.degrees(180), axis: (x: 1, y: 0, z: 0))
                    }
                }
        }
    }
}
