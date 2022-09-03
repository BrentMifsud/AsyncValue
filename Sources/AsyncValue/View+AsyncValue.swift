//
//  View+AsyncValue.swift
//  
//
//  Created by Brent Mifsud on 2022-09-02.
//

#if canImport(SwiftUI)

import SwiftUI

public extension View {
    /// Adds a modifier for this view that fires an action when a specific `AsyncValue` changes.
    /// - Parameters:
    ///   - stream: the async stream to recieve updates from
    ///   - handler: handler for new values
    /// - Returns: some View
    ///
    /// This view modifier works very similarly to `.onReceive(publisher:perform:)` and `.onChange(value:perform:)`
    ///
    /// ```swift
    ///  struct MyView: View {
    ///     var body: some View {
    ///         Text("Hello World!")
    ///             .onReceive(myService.$myValue) { value in
    ///                 print("The value changed to: \(value)")
    ///             }
    ///     }
    ///  }
    ///
    ///  class MyService: ObservableObject {
    ///     @AsyncValue var myValue: String = "Test" {
    ///         willSet { objectWillChange.send() }
    ///     }
    ///  }
    /// ```
    @ViewBuilder func onReceive<Value>(
        _ stream: AsyncStream<Value>,
        perform handler: @escaping (Value) async -> Void
    ) -> some View {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            task {
                for await value in stream {
                    await handler(value)
                }
            }
        } else {
            var task: Task<Void, Never>? = nil
            
            onAppear {
                task = Task {
                    for await value in stream {
                        await handler(value)
                    }
                }
            }
            .onDisappear {
                task?.cancel()
            }
        }
    }
}

#endif
