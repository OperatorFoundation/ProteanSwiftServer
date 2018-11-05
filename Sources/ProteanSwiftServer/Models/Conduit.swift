//
//  Conduit.swift
//  ProteanSwiftServer
//
//  Created by Adelita Schule on 9/29/18.
//

import Foundation
import Transport

class Conduit: NSObject
{
    var idNumber: Int
    var wireGuardConnection: Connection
    var transportConnection: Connection
    var outgoingPort: UInt
    
    init(wireGuardConnection: Connection, transportConnection: Connection, withID idNumber: Int, andPort port: UInt)
    {
        self.wireGuardConnection = wireGuardConnection
        self.transportConnection = transportConnection
        self.idNumber = idNumber
        self.outgoingPort = port
    }
}
