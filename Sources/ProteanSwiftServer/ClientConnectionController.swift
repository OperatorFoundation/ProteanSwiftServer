//
//  ClientConnectionController.swift
//  ProteanSwiftServer
//
//  Created by Adelita Schule on 9/29/18.
//

import Foundation
import Transport

class ClientConnectionController: NSObject
{
    var connections: [Int: ClientConnection] = [:]
    var lastConnectionID: Int = 0
    var lastPort: UInt = 49000
    
    func addConnection(connection: Connection)
    {
        lastConnectionID += 1
        lastPort += 1
        let newClientConnection = ClientConnection(connection: connection, withID: lastConnectionID, andPort: lastPort)
        //connections.
    }
}
