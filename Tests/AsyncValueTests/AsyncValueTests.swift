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
            try await Task.sleep(nanoseconds: 1_000_000)
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
            try await Task.sleep(nanoseconds: 1_000_000)
            sut?.wrappedValue = "Finish"
        }
        
        await testTask.value
    }
}
