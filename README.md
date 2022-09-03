[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FBrentMifsud%2FAsyncValue%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/BrentMifsud/AsyncValue)

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FBrentMifsud%2FAsyncValue%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/BrentMifsud/AsyncValue)

[![Build](https://github.com/BrentMifsud/AsyncValue/actions/workflows/Build.yml/badge.svg)](https://github.com/BrentMifsud/AsyncValue/actions/workflows/Build.yml)

# AsyncValue

This is a simple package that provides a convenience property wrapper around AsyncStream that behaves almost identically to `@Published`.

# Installation

## Via Xcode

1. In the project navigator on the left, click on your project
2. click `Package Dependencies`
3. enter: [https://github.com/BrentMifsud/AsyncValue.git](https://github.com/BrentMifsud/AsyncValue.git) into the search bar
4. select the desired version and click `Add Package`

## Via Package.swift

in your `Package.swift` file, add the following:

```swift
let package = Package(
    name: "MyPackage",
    dependencies: [
        .package(url: "https://github.com/BrentMifsud/AsyncValue.git", from: .init(1, 0, 0))
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "MyPackage",
            targets: ["MyPackage"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "MyPackage",
            dependencies: ["AsyncValue"]
        ),
        .testTarget(
            name: "MyPackageTests",
            dependencies: ["MyPackage"]
        ),
    ]
)
```

# Usage

## Accessing the current value

```swift
@AsyncValue var myValue: String = "Test"

print(myValue) // prints: test
```

## Observing changes to the value

Just like the publisher backing `@Published`, `AsyncValue` is backed by an AsyncStream. And you can subscribe to updates to the value.

```swift
@AsyncValue myValue: String = "Test"

Task {
    for await value in myValue {
        print("Value: \(value)")
    }
}

Task {
    await Task.sleep(nanoseconds: 1_000_000_000)
    myValue = "New Value"
}

/* Prints:
Value: test
Value: New Value
*/
```

## Observing with multiple tasks

One of the major limitations of AsyncStream out of the box is that you can only `for-await-in` on it with a single task.

`AsyncValue` does not have this limitation:

```swift
@AsyncValue myValue: String = "Test"

Task {
    for await value in myValue {
        print("Task 1 Value: \(value)")
    }
}

Task {
    for await value in myValue {
        print("Task 2 Value: \(value)")
    }
}

Task {
    await Task.sleep(nanoseconds: 1_000_000_000)
    myValue = "New Value"
}

/* Prints (note that the order of the tasks printing may vary as this is happening asyncronously):
Task 1 Value: test
Task 2 Value: test
Task 2 Value: New Value
Task 1 Value: New Value
*/
```

## Using with SwiftUI

`AsyncValue` can be adapted to work seamlessly with `ObservableObject` with a single line of code:

```swift
class MyObservableObject: ObservableObject {
    @AsyncValue var myValue: String = "Test" {
        // IMPORTANT: you must use `willSet` as that is what `@Published` uses under the hood
        willSet { objectWillChange.send() }
    }
}
```

There is also an `.onRecieve(stream:perform:)` view modifier that allows you to respond to changes from an @AsyncValue

```swift
struct MyView: View {
    var body: some View {
        Text("Hello World!")
            .onReceive(myService.$myValue) { value in
                print("The value changed to: \(value)")
            }
    }
}

class MyService: ObservableObject {
    @AsyncValue var myValue: String = "Test" {
        willSet { objectWillChange.send() }
    }
}
```
