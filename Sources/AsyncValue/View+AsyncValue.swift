//
//  View+AsyncValue.swift
//  
//
//  Created by Brent Mifsud on 2022-09-02.
//

#if canImport(SwiftUI)

import SwiftUI

public extension View {
    /// Adds a modifier for this view that fires an action when a specific `AsyncSequence` yields new values.
    /// - Parameters:
    ///   - sequence: the async sequence to recieve updates from
    ///   - handler: handler for new values
    /// - Returns: some View
    ///
    /// This view modifier works very similarly to `.onReceive(publisher:perform:)` and `.onChange(value:perform:)`
    ///
    /// A warning will be printed to the console if the provided `AsyncSequence` throws an error. And no new values will be returned.
    /// As such, it is recommended that `AsyncStream` is used rather than a custom `AsyncSequence` implementation.
    ///
    /// ```swift
    ///  struct MyView: View {
    ///     var body: some View {
    ///         Text("Hello World!")
    ///             .onReceive(myService.$myValue) { value in
    ///                 print("The value changed to: \(value)")
    ///             }
    ///             .onReceive(myService.myStream) { newValue in
    ///                 print("My stream value changed to: \(newValue)")
    ///             }
    ///     }
    ///  }
    ///
    ///  class MyService: ObservableObject {
    ///     @AsyncValue var myValue: String = "Test" {
    ///         willSet { objectWillChange.send() }
    ///     }
    ///
    ///     lazy var myStream: AsyncStream<Int> = {
    ///         // initialize and return some async stream here
    ///     }()
    ///  }
    /// ```
    @ViewBuilder func onReceive<Sequence: AsyncSequence>(
        _ sequence: Sequence,
        perform handler: @escaping (Sequence.Element) async -> Void
    ) -> some View {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            task {
                do {
                    for try await value in sequence {
                        await handler(value)
                    }
                } catch is CancellationError {
                    // cancellation errors are valid and we can ignore them.
                } catch {
                    Self.printErrorWarning(error: error, sequence: sequence, function: #function, line: #line, file: #file)
                }
            }
        } else {
            var task: Task<Void, Never>? = nil
            
            onAppear {
                task = Task {
                    do {
                        for try await value in sequence {
                            await handler(value)
                        }
                    } catch is CancellationError {
                        // cancellation errors are valid and we can ignore them.
                    } catch {
                        Self.printErrorWarning(error: error, sequence: sequence, function: #function, line: #line, file: #file)
                    }
                }
            }
            .onDisappear {
                task?.cancel()
            }
        }
    }
    
    private static func printErrorWarning(
        error: Error,
        sequence: any AsyncSequence,
        function: StaticString = #function,
        line: Int = #line,
        file: StaticString = #file
    ) {
        print("""
        [AsyncValue] - warning: usage of .onReceive(sequence:handler:) with unhandled throwing sequence at: \(file) \(function) \(line)
        The AsyncSequence throwing the error: \(type(of: sequence))
        The error has been caught here to help with debugging purposes: \(String(describing: error))
        Please handle any errors thrown in your custom AsyncSequence implementation, or try using AsyncStream instead.
        """)
    }
}

#endif
