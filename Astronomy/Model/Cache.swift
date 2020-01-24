//
//  Cache.swift
//  Astronomy
//
//  Created by Enayatullah Naseri on 1/23/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import Foundation

class Cache<Key: Hashable, Value> {
    
    // Properties
    private var cache: [Key : Value] = [:]
    private let queue = DispatchQueue(label: "CatchQueueAstronomy")
    
    // Cache function
    func cache(value: Value, key: Key) {
        queue.async {
            self.cache[key] = value
        }
    }
    
    func value(key: Key) -> Value? {
        return queue.sync { cache[key] }
    }
}
