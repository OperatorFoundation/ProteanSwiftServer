//
//  ConduitCollection.swift
//  ProteanSwiftServer
//
//  Created by Adelita Schule on 10/29/18.
//

import Foundation
import Transport

class ConduitCollection: NSObject
{
    private var conduits: [Int: Conduit] = [:]
    private var lastConnectionID: Int = 0
    private var lastPort: UInt = 49000
    
    func addConduit(wireGuardConnection: Connection, transportConnection: Connection) -> Int
    {
        lastConnectionID += 1
        lastPort += 1
        let newConduit = Conduit(wireGuardConnection: wireGuardConnection, transportConnection: transportConnection, withID: lastConnectionID, andPort: lastPort)
        conduits[lastConnectionID] = newConduit
        
        return lastConnectionID
    }
    
    func removeConduit(withID clientID: Int)
    {
        conduits.removeValue(forKey: clientID)
    }
    
    func getConduit(withID clientID: Int) -> Conduit?
    {
        if let conduit = conduits[clientID]
        {
            return conduit
        }
        
        return nil
    }
}
