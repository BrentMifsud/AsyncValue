//
//  AsyncValue.swift
//
//
//  Created by Brent Mifsud on 2022-09-01.
//

import Foundation
#if canImport(Combine)
import Combine
#endif

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
///   Usage with Combine's `ObseravbleObject`:
///
///   ```swift
///     class MyObservableOjbect: ObservableObject {
///         @AsyncValue var myValue = "Test"
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
    
    // Implementing the subscript in an extension does not seem to be picked up by the compiler
    // so implement it here instead.
    #if canImport(Combine)
    /// Creates a new `AsyncValue` within the specified instance
    /// - Parameter instance: The class in which the property is created
    /// - Parameter wrappedKeyPath: `KeyPath` to the wrapped value property
    /// - Parameter storageKeyPath: `KeyPath` to the enclosing instance
    ///
    /// The default implementation of the `ObservableObject` protocol falls back to
    /// the `ObservableObjectPublisher`.
    /// Here, we use the static subscript implementation described in the
    /// [Swift Evolution Proposal](https://github.com/apple/swift-evolution/blob/main/proposals/0258-property-wrappers.md#referencing-the-enclosing-self-in-a-wrapper-type)
    /// as mentioned by [John Sundell](https://www.swiftbysundell.com/articles/accessing-a-swift-property-wrappers-enclosing-instance/)
    /// to indicate changes made to an `@AsyncValue`.
    ///
    /// The compiler will use the static subscript whenever the enclosing type of the property wrapper
    /// is a class.
    ///
    /// Due to a limitation in the compiler ([apple/swift#54777](https://github.com/apple/swift/issues/54777))
    /// only *one* subscript may be specified.
    /// Therefore, the set method dynamically check if the type of the instance is an `ObservableObject`
    /// that implements the default `ObservableObjectPublisher`
    public static subscript<T: AnyObject>(
        _enclosingInstance instance: T,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<T, Self>
    ) -> Value {
        get {
            // Return the saved wrapped value
            instance[keyPath: storageKeyPath].wrappedValue
        }
        set {
            // Dynamically call objectWillChange if available
            if let instance = instance as? any ObservableObject,
               let publisher = (instance.objectWillChange as any Publisher) as? ObservableObjectPublisher {
                // Trigger the `ObjectWillChangePublisher`
                publisher.send()
            }
            instance[keyPath: storageKeyPath].wrappedValue = newValue
        }
    }

    #endif
}
