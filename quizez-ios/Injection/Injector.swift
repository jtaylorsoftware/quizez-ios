//
//  Injector.swift
//  quizez-ios
//
//  Created by Jeremy Taylor on 7/22/21.
//

import Foundation

/// A  simple dependency injector, probably not thread safe.
class Injector {
    typealias ResolverFunc<T> = (Injector) -> T
    
    /// Global shared instance
    static let shared = Injector()
    
    /// Stores dependency singleton instances and their resolvers
    private var dependencies: [ObjectIdentifier: (Any?, ResolverFunc<Any>)] = [:]
    
    /// Tracks the current types being resolved, to break cycles
    private var resolverRecord =  Set<ObjectIdentifier>()
    
    /// Registers a resolver function for a dependency type.
    func register<T>(_ type: T.Type, resolver: @escaping ResolverFunc<T>) {
        let identifier = ObjectIdentifier(type)
        dependencies[identifier] = (nil, resolver)
    }
    
    /// Resolves a dependency type, returning an instance of that type, instantiating
    /// it if necessary.
    /// - Returns: an instance of given type or nil if it's not registered.
    func resolve<T>() -> T? {
        let identifier = ObjectIdentifier(T.self)
        guard !resolverRecord.contains(identifier) else {
            fatalError("Circular dependencies detected")
        }
        resolverRecord.insert(identifier)
        defer {
            resolverRecord.remove(identifier)
        }
        
        guard let (instance, resolver) = dependencies[identifier] else {
            return nil
        }
        
        if let dependency = instance {
            return dependency as? T
        }
        let newInstance = resolver(self) as! T
        dependencies[identifier] = (newInstance, resolver)
        return newInstance
    }
}
