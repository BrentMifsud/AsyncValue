//
//  View+AsyncValue.swift
//  
//
//  Created by Brent Mifsud on 2022-09-02.
//

#if canImport(SwiftUI)

import SwiftUI

extension View {
    /// Adds a modifier for this view that fires an action when a specific `AsyncValue` changes.
    /// - Parameters:
    ///   - asyncStream: the async stream to recieve updates from
    ///   - valueRecieved: handler for new values
    /// - Returns: some View
    @ViewBuilder public func onChange<Value>(
        of asyncStream: AsyncStream<Value>,
        valueRecieved: @escaping (Value) async -> Void
    ) -> some View {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            task {
                for await value in asyncStream {
                    await valueRecieved(value)
                }
            }
        } else {
            var task: Task<Void, Never>? = nil
            
            onAppear {
                task = Task {
                    for await value in asyncStream {
                        await valueRecieved(value)
                    }
                }
            }
            .onDisappear {
                task?.cancel()
            }
            .eraseToAnyView()
        }
    }
    
    internal func eraseToAnyView() -> some View {
        AnyView(self)
    }
}

#endif
