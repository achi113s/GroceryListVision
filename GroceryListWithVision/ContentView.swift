//
//  ContentView.swift
//  GroceryListWithVision
//
//  Created by Giorgio Latour on 8/15/23.
//

import SwiftUI
import Vision

struct ContentView: View {
    @StateObject private var recipeItems: RecipeItems = RecipeItems()
    
    @State private var image: UIImage = UIImage()
    @State private var showingCamera: Bool = false
    @State private var recognizedTextBoundingBoxes: [CGRect] = []
    @State private var requestInProgress: Bool = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 15) {
                Image(uiImage: self.image)
                    .resizable()
                    .padding(.all, 4)
                    .frame(width: 100, height: 100)
                    .background(
                        ZStack {
                            Color.black.opacity(0.2)
                            Text("Image")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    )
                    .aspectRatio(contentMode: .fill)
                    .padding(8)
                
                HStack {
                    Button {
                        showingCamera = true
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.blue.opacity(0.2))
                            Text("Take Picture")
                        }
                    }
                    .frame(width: 150, height: 55)
                    
                    Button {
                        withAnimation(.easeInOut(duration: 1)) {
                            requestInProgress = true
                        }
                        DispatchQueue.global(qos: .userInitiated).async {
                            processImage()
                        }
//                        Task.detached(priority: .medium) {
//                            await processImage()
//                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.blue.opacity(0.2))
                            Text("Process Picture")
                        }
                    }
                    .frame(width: 150, height: 55)
                }
                
                Text("Image Text 👇🏼")
                
                List {
                    ForEach(recipeItems.recipeItems, id: \.id) { item in
                        HStack {
                            Toggle("", isOn: $recipeItems.recipeItems[recipeItems.recipeItems.firstIndex(of: item)!].complete)
                                .toggleStyle(CheckboxToggleStyle())
                            Text("\(item.name)")
                            Spacer()
                        }
                    }
                    .listRowBackground(Color(white: 0.95, opacity: 0.7))
                }
                .frame(height: 500)
                .scrollContentBackground(.hidden)
                
            }
            .padding()
            
            if requestInProgress {
                ProgressView()
                    .transition(.slide)
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(selectedImage: $image)
                .edgesIgnoringSafeArea(.bottom)
        }
        //        .sheet(isPresented: $isDoneWithRequest) {
        //            ImageViewWithTextBoxes(image: image, textBoundingBoxes: recognizedTextBoundingBoxes)
        //        }
    }
    
    func processImage() {
        guard let cgImage = image.cgImage else { return }
        print("Current Thread: \(Thread.current)")
        let myImageTextRequest = VNImageRequestHandler(cgImage: cgImage)
        
        // VNRecognizeTextRequest provides text-recognition capabilities.
        // The default is the "accurate" method which does neural-network based text detection and recognition.
        // It is slower but more accurate and since I am not using a live camera feed text recognition this is
        // a good option.
        let request = VNRecognizeTextRequest(completionHandler: addObservationsToList)
        request.recognitionLevel = .accurate
        request.progressHandler = myProgressHandler
        
        // For consistency, use revision 3 of the model.
        request.revision = 3
        // Prefer processing in the background.
        request.preferBackgroundProcessing = true
        
        do {
            try myImageTextRequest.perform([request])
        } catch {
            print("Could not perform request: \(error.localizedDescription)")
        }
    }
    
    // Completion handler for the image text recognition request.
    func addObservationsToList(request: VNRequest, error: Error?) {
        // Retrieve the results of the request, which is an array of VNRecognizedTextObservation objects.
        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
        print("Current Thread: \(Thread.current). Should not be main.")
        let results = observations.compactMap { observation in
            // topCandidates returns an array of the top n candidates as VNRecognizedText objects.
            // Then we use first to get that top candidate.
            // Then we access the string parameter, which is the text as a String type.
            // The resulting type of recognizedStrings is then [String].
            
            // The bounding box is in normalized coordinates, so we need to convert it.
            //            return VNImageRectForNormalizedRect(
            //                observation.boundingBox,
            //                Int(image.size.width),
            //                Int(image.size.height)
            //            )
            
            return (observation.boundingBox, observation.topCandidates(1)[0].string)
        }
        
        let recognizedItems = recognizeIngredientsByLineSpacing(results)
        
        // We want to keep all the bounding boxes not just the ones that survive processing.
        let recognizedStringsBoundingBoxes = results.map { result in
            return result.0
        }
        
//        print(recognizedItems)
//        print(recognizedStringsBoundingBoxes)
        
        DispatchQueue.main.async {
            print("Current Thread: \(Thread.current). Should be main.")
            recipeItems.recipeItems = recognizedItems
            recognizedTextBoundingBoxes = recognizedStringsBoundingBoxes
            withAnimation(.easeInOut(duration: 1)) {
                requestInProgress = false
            }
        }
    }
    
    private func myProgressHandler(request: VNRequest, progress: Double, error: Error?) {
        print(progress)
    }
    
    private func recognizeIngredientsByLineSpacing(_ observations: [(CGRect, String)]) -> [RecipeItem] {
        /* Process the results from the VNRecognizeTextRequest based on the spatial
         relationship between the observations. This does not generalize well. In this
         case, we will consider the situation where ingredients are wrapped on new lines
         and each is separated by a blank new line. Hence, if the spacing between one observation
         and the next is small, means those two lines are part of the same ingredient.
         */
        print("Current Thread: \(Thread.current). Should not be main")
        let lineHeightThreshold = 0.8
        
        // Find the maximum and minimum space between observations.
        var minSpacing: CGFloat = .infinity  // Presumed to be the line spacing.
        var maxSpacing: CGFloat = -.infinity  // Presumed to be the paragraph spacing.
        for index in stride(from: 0, to: observations.count - 1, by: 1) {
            let firstObservation = observations[index]
            
            if index + 1 < observations.count {
                let secondObservation = observations[index + 1]
                
                let verticalSpacing = firstObservation.0.origin.y - secondObservation.0.origin.y
                
                if verticalSpacing < minSpacing { minSpacing = verticalSpacing }
                if verticalSpacing >= maxSpacing { maxSpacing = verticalSpacing }
            }
        }
        
//        print("The minimum space between observations is \(minSpacing).")
//        print("The maximum line spacing is \(maxSpacing).")
        
        var groupedObservedStrings = [RecipeItem]()
        var buildIngredient = observations[0].1  // Start building on the first observation.
        
        for index in stride(from: 0, to: observations.count - 1, by: 1) {
            let firstObservation = observations[index]
            
            // Make sure we don't go out of index bounds.
            if index + 1 < observations.count {
                let secondObservation = observations[index + 1]
                
                let verticalSpacing = firstObservation.0.origin.y - secondObservation.0.origin.y
//                print("The vertical spacing between \(firstObservation.1) and \(secondObservation.1) is \(verticalSpacing).")
                
                // If the spacing between observations is less than lineHeightThreshold times the maximum spacing,
                // it's likely this is part of one ingredient.
                if verticalSpacing < (maxSpacing * lineHeightThreshold) {
//                    print("\(firstObservation.1) and \(secondObservation.1) are part of the same ingredient.")
                    buildIngredient = "\(buildIngredient) \(secondObservation.1)"
//                    print(buildIngredient)
                } else {
                    // The buildIngredient will be blank if this is the beginning of an ingredient after
                    // a blank line.
                    if !buildIngredient.isEmpty {
                        let recipeItem = RecipeItem(name: buildIngredient)
                        groupedObservedStrings.append(recipeItem)
                        buildIngredient = secondObservation.1
                    } else {
                        let recipeItem = RecipeItem(name: secondObservation.1)
                        groupedObservedStrings.append(recipeItem)
                    }
                }
            }
        }
        
        if !buildIngredient.isEmpty {
            let recipeItem = RecipeItem(name: buildIngredient)
            groupedObservedStrings.append(recipeItem)
        }
        
        return groupedObservedStrings
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


