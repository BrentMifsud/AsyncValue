//
//  ContinuationStorage.swift
//  
//
//  Created by Brent Mifsud on 2022-09-02.
//

import Foundation

class ContinuationStorage<Value> {
    typealias Continuation = AsyncStream<Value>.Continuation
    
    private var continuations: [UUID: Continuation] = [:]
    
    func addContinuation(_ continuation: Continuation, for uuid: UUID) {
        continuations[uuid] = continuation
    }
    
    func removeContinuation(for uuid: UUID) {
        continuations[uuid] = nil
    }
    
    func clearContinuations() {
        continuations.removeAll()
    }
    
    func yield(_ value: Value) {
        for (_, continuation) in continuations {
            continuation.yield(value)
        }
    }
    
    deinit {
        clearContinuations()
    }
}
