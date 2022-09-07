//
//  AsyncValue.swift
//
//
//  Created by Brent Mifsud on 2022-09-01.
//

import Foundation

/// A swift concurrency equivalent to `@Published`
///
///   ```swift
///   @AsyncValue myValue: String = "Test"
///
///   // You can access its current value just like any property wrapper
///   print(myValue) // prints: "Test"
///
///   // You can subscribe to this value from mulitple tasks
///   Task {
///       for await value in $myValue {
///           print("Task 1 value: \(value)")
///       }
///   }
///
///   Task {
///       for await value in $myValue {
///           print("Task 2 value: \(value)")
///       }
///   }
///
///   Task {
///       Task.sleep(5_000_000_000) // wait 5 seconds
///       myValue = "new value"
///   }
///
///   // the below will be printed:
///   // Task 1 value: Test
///   // Task 2 value: Test
///   // Task 1 value: new value
///   // Task 2 value: new value
///   ```
///
///   Ignoring updates if the new value is the same as the old value:
///
///   ```swift
///   @AsyncValue(behavior: .newValues) myOtherValue: String = "Test"
///
///   print(myOtherValue) // prints: "Test"
///
///   // You can subscribe to this value from mulitple tasks
///   Task {
///       for await value in $myOtherValue {
///           print("Task value: \(value)")
///       }
///   }
///
///   Task {
///       Task.sleep(5_000_000_000) // wait 5 seconds
///       myOtherValue = "new value"
///   }
///
///   // the below will be printed:
///   // Task value: new value
///   ```
///
///   Usage with SwiftUI's `ObseravbleObject`:
///
///   ```swift
///     @AsyncValue var myValue = "Test" {
///         willSet { objectWillChange.send() }
///     }
///   ```
@propertyWrapper
public struct AsyncValue<Value: Equatable> {
    public enum YieldBehavior {
        case newValues
        case allValues
    }
    
    public var wrappedValue: Value {
        didSet {
            if behavior == .newValues && oldValue != wrappedValue {
                storage.yield(wrappedValue)
            } else if behavior == .allValues {
                storage.yield(wrappedValue)
            }
        }
    }
    
    public var projectedValue: AsyncStream<Value> {
        AsyncStream { continuation in
            let uuid = UUID()
            storage.addContinuation(continuation, for: uuid)
            
            if behavior == .allValues {
                continuation.yield(wrappedValue)
            }
            
            continuation.onTermination = { @Sendable _ in
                storage.removeContinuation(for: uuid)
            }
        }
    }
    
    private var storage: ContinuationStorage<Value>
    private var behavior: YieldBehavior
    
    /// Create a new `AsyncValue` with the specified initial value and behavior.
    /// - Parameter wrappedValue: the initial value.
    /// - Parameter behavior: how the `AsyncValue` publishes its updates. Defaults to `YieldBehavior.allValues`
    public init(wrappedValue: Value, behavior: YieldBehavior = .allValues) {
        self.wrappedValue = wrappedValue
        self.behavior = behavior
        storage = ContinuationStorage()
    }
}
