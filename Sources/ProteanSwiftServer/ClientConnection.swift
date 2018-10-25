//
//  ClientConnection.swift
//  ProteanSwiftServer
//
//  Created by Adelita Schule on 9/29/18.
//

import Foundation
import Transport

class ClientConnection: NSObject
{
    var idNumber: Int
    var connection: Connection
    var outgoingPort: UInt
    
    init(connection: Connection, withID idNumber: Int, andPort port: UInt)
    {
        self.connection = connection
        self.idNumber = idNumber
        self.outgoingPort = port
    }
}
