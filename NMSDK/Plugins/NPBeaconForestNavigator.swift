//
//  NPBeaconForestNavigator.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 15/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import CoreLocation
import NMPlug
import NMNet

class NPBeaconForestNavigator {
    private var plugin: Pluggable!
    
    var defaultRegionIdentifiers: Set<String> {
        var identifiers = Set<String>()
        
        let resources: [APBeaconForestNode] = (plugin.hub?.cache.resourcesIn(collection: "DefaultRegions", forPlugin: plugin) ?? [])
        for resource in resources where !identifiers.contains(resource.id) && resource.isRoot {
            identifiers.insert(resource.id)
        }
        
        return identifiers
    }
    
    init(plugin aPlugin: Pluggable) {
        plugin = aPlugin
    }
    
    func enter(regionIdentifier: String) -> Set<String> {
        var ignoredFlag = false
        return enter(regionIdentifier, forceForestNavigation: &ignoredFlag)
    }
    func enter(regionIdentifier: String, inout forceForestNavigation: Bool) -> Set<String> {
        forceForestNavigation = false
        
        /// The current region does not exist -> return root regions
        guard let node = self[regionIdentifier] else {
            forceForestNavigation = true
            return defaultRegionIdentifiers
        }
        
        /// If the current node is root
        guard let l1Parent = up(node, levels: 1) else {
            return Set(node.children).union(defaultRegionIdentifiers)
        }
        
        /// If the current node is leaf
        if node.children.count <= 0 {
            /// If the parent is root, return all roots plus current node's brothers
            guard let l2Parent = up(l1Parent, levels: 1) else {
                return Set(l1Parent.children).union(defaultRegionIdentifiers)
            }
            
            /// Otherwise return children of parent's parent plus node's brothers
            return Set(l1Parent.children).union(l2Parent.children)
        }
        
        /// Return children of the current node plus nodes at the same level of the current node
        return Set(node.children).union(l1Parent.children)
    }
    func exit(regionIdentifier: String) -> Set<String> {
        var ignoredFlag = false
        return exit(regionIdentifier, forceForestNavigation: &ignoredFlag)
    }
    func exit(regionIdentifier: String, inout forceForestNavigation: Bool) -> Set<String> {
        forceForestNavigation = false
        
        /// The current region does not exist -> return root regions
        guard let node = self[regionIdentifier] else {
            forceForestNavigation = true
            return defaultRegionIdentifiers
        }
        
        /// If the current region is root
        guard let l1Parent = up(node, levels: 1) else {
            forceForestNavigation = true
            return defaultRegionIdentifiers
        }
        
        /// If the current node is leaf
        if node.children.count <= 0 {
            /// If the parent is root, return all roots plus current node's brothers
            guard let l2Parent = up(l1Parent, levels: 1) else {
                return Set(l1Parent.children).union(defaultRegionIdentifiers)
            }
            
            /// Otherwise return children of parent's parent plus node's brothers
            return Set(l1Parent.children).union(Set(l2Parent.children))
        }
        
        /// If the region is not leaf or root and l1Parent is root, return root nodes plus current node's brothers (including current node)
        guard let l2Parent = up(l1Parent, levels: 2) else {
            return Set(l1Parent.children).union(defaultRegionIdentifiers)
        }
        
        /// Otherwise, return current node's brothers, current node's parent and its brothers
        return Set(l1Parent.children).union(Set(l2Parent.children))
    }
    func identifiersToRegions(identifiers: Set<String>) -> Set<CLBeaconRegion> {
        var regions = Set<CLBeaconRegion>()
        for id in identifiers {
            guard let region = identifierToRegion(id) else {
                continue
            }
            
            regions.insert(region)
        }
        
        return regions
    }
    func identifierToRegion(id: String) -> CLBeaconRegion? {
        guard let node = self[id], major = node.major, minor = node.minor else {
            return nil
        }
        
        return CLBeaconRegion(proximityUUID: node.proximityUUID, major: UInt16(major), minor: UInt16(minor), identifier: node.id)
    }
    
    // MARK: Private
    private func up(current: APBeaconForestNode, levels: Int) -> APBeaconForestNode? {
        if levels <= 0 {
            return current
        }
        
        var levelsLeft = levels
        var parent: APBeaconForestNode?
        while levelsLeft > 0 {
            guard let parentIdentifier = current.parent, newParent = self[parentIdentifier] else {
                return nil
            }
            
            parent = newParent
            levelsLeft -= 1
        }
        
        return parent
    }
    private subscript(id: String) -> APBeaconForestNode? {
        let resources: [APBeaconForestNode] = (plugin.hub?.cache.resourcesIn(collection: "Regions", forPlugin: plugin) ?? [])
        for resource in resources where resource.id == id {
            return resource
        }
        
        return nil
    }
}
