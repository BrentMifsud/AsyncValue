//
//  ContentView.swift
//  AsyncValueTestApp
//
//  Created by Brent Mifsud on 2022-09-02.
//

import AsyncValue
import SwiftUI

struct ContentView: View {
    static var defaultValue = "Test"
    @StateObject private var testService = AsyncValueTestService()
    @State private var onChangeValue: String = Self.defaultValue
    
    var body: some View {
        VStack {
            Text("ObservableObject: \(testService.testValue)")
                .accessibilityIdentifier("observed-object-value")
            
            Text(".onChange: \(onChangeValue)")
                .accessibilityIdentifier("on-change-value")
                .onChange(of: testService.$testValue) { value in
                    onChangeValue = value
                }
            
            HStack {
                Button {
                    testService.testValue = "Updated Value"
                } label: {
                    Text("Change Value")
                }
                .accessibilityIdentifier("change-value")
                
                Button {
                    testService.testValue = Self.defaultValue
                } label: {
                    Text("Reset Value")
                }
                .accessibilityIdentifier("reset-value")
            }
        }
        .padding()
        .fixedSize(horizontal: true, vertical: true)
    }
}

class AsyncValueTestService: ObservableObject {
    @AsyncValue public var testValue = ContentView.defaultValue
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

