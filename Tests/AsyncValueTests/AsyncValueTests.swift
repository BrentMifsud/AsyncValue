import XCTest
@testable import AsyncValue

final class AsyncValueTests: XCTestCase {
    var sut: AsyncValue<String>?

    override func tearDown() {
        super.tearDown()
        sut = nil
    }
    
    
    func test_allValues() async throws {
        sut = .init(wrappedValue: "Test")
        
        let testTask = Task {
            var values = [String]()
            
            for await value in sut!.projectedValue {
                values.append(value)
                
                if value == "Finish" {
                    break
                }
            }
            
            XCTAssertEqual(values, ["Test", "Finish"])
        }
        
        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            sut?.wrappedValue = "Finish"
        }
        
        await testTask.value
    }
    
    func test_newValues() async throws {
        sut = .init(wrappedValue: "Test", behavior: .newValues)
        
        let testTask = Task {
            var values = [String]()
            
            for await value in sut!.projectedValue {
                values.append(value)
                
                if value == "Finish" {
                    break
                }
            }
            
            XCTAssertEqual(values, ["Finish"])
        }
        
        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            sut?.wrappedValue = "Finish"
        }
        
        await testTask.value
    }
}

#if canImport(Combine) && canImport(SwiftUI)
import Combine
import SwiftUI

extension AsyncValueTests {
    fileprivate class TestObservableObject: ObservableObject {
        @AsyncValue var myValue = "Test"
    }

    func test_observableObjectPublisher() {
        let sut = TestObservableObject()
        
        let exp = expectation(description: "wait for combine publisher")
        
        var updateCount: Int = 0
        
        let cancellable = sut.objectWillChange.sink {
            updateCount += 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            sut.myValue = "Test 2"
            sut.myValue = "Finish"
            exp.fulfill()
        })
        
        waitForExpectations(timeout: 3)
        
        // Since we subscribed after the observable object is created, the initial state of "Test".
        // Cannot trigger a new value in our sink block above.
        XCTAssertEqual(updateCount, 2)
        cancellable.cancel()
    }
}
#endif
