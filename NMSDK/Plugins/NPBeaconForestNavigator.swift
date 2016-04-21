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
    
    var defaultRegionIdentifiers: [String] {
        var identifiers = [String]()
        
        let resources: [APBeaconForestNode] = (plugin.hub?.cache.resourcesIn(collection: "DefaultRegions", forPlugin: plugin) ?? [])
        for resource in resources where !identifiers.contains(resource.id) && resource.isRoot {
            identifiers.append(resource.id)
        }
        
        return identifiers
    }
    
    init(plugin aPlugin: Pluggable) {
        plugin = aPlugin
    }
    
    func enter(regionIdentifier: String) -> [String] {
        /// The current region does not exist -> return root regions
        guard let node = self[regionIdentifier] else {
            return defaultRegionIdentifiers
        }
        
        /// If the current node is root
        guard let l1Parent = up(node, levels: 1) else {
            return node.children + defaultRegionIdentifiers
        }
        
        /// If the current node is leaf
        if node.children.count <= 0 {
            /// If the parent is root, return all roots plus current node's brothers
            guard let l2Parent = up(l1Parent, levels: 1) else {
                return l1Parent.children + defaultRegionIdentifiers
            }
            
            /// Otherwise return children of parent's parent plus node's brothers
            return l1Parent.children + l2Parent.children
        }
        
        /// Return children of the current node plus nodes at the same level of the current node
        return node.children + l1Parent.children
    }
    func exit(regionIdentifier: String) -> [String] {
        /// The current region does not exist -> return root regions
        guard let node = self[regionIdentifier] else {
            return defaultRegionIdentifiers
        }
        
        /// If the current region is root
        guard let l1Parent = up(node, levels: 1) else {
            return defaultRegionIdentifiers
        }
        
        /// If the current node is leaf
        if node.children.count <= 0 {
            /// If the parent is root, return all roots plus current node's brothers
            guard let l2Parent = up(l1Parent, levels: 1) else {
                return l1Parent.children + defaultRegionIdentifiers
            }
            
            /// Otherwise return children of parent's parent plus node's brothers
            return l1Parent.children + l2Parent.children
        }
        
        /// If the region is not leaf or root and l1Parent is root, return root nodes plus current node's brothers (including current node)
        guard let l2Parent = up(l1Parent, levels: 2) else {
            return l1Parent.children + defaultRegionIdentifiers
        }
        
        /// Otherwise, return current node's brothers, current node's parent and its brothers
        return l1Parent.children + l2Parent.children
    }
    func identifiersToRegions(identifiers: [String]) -> [CLRegion] {
        var regions = [CLRegion]()
        for id in identifiers {
            guard let node = self[id], major = node.major, minor = node.minor else {
                continue
            }
            
            regions.append(CLBeaconRegion(proximityUUID: node.proximityUUID, major: UInt16(major), minor: UInt16(minor), identifier: node.id))
        }
        
        return regions
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
