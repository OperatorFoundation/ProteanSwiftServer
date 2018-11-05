//
//  ProteanListener.swift
//  ProteanSwiftServer
//
//  Created by Adelita Schule on 9/7/18.
//

import Foundation
import Network
import Transport
import Protean
import ProteanSwift

public class ProteanListener: Listener
{
    public var newTransportConnectionHandler: ((_ connection: Connection) -> Void)?
    
     public var newConnectionHandler: ((Connection) -> Void)?
    
    public var debugDescription: String = "[UDPListener]"
    
    public var parameters: NWParameters
    
    public var port: NWEndpoint.Port?
    
    public var queue: DispatchQueue? = DispatchQueue(label: "UDP Server Queue")
    
    public var stateUpdateHandler: ((NWListener.State) -> Void)?
    
    public var proteanConfig: ProteanSwift.Protean.Config
    
    var listener: Listener
    
    
    public required init(using parameters: NWParameters, config: ProteanSwift.Protean.Config, on port: NWEndpoint.Port) throws
    {
        self.parameters = parameters
        self.port = port
        self.proteanConfig = config
        
        // Create the listener
        do
        {
            listener = try NWListener(using: .udp, on: port)        
        }
        catch
        {
            print("😮  Listener creation error.  😮")
            throw ListenerError.initializationError
        }
    }
    
    //MARK: Transport API Listener Protocol
    public func start(queue: DispatchQueue)
    {
        // Start the listener
        listener.stateUpdateHandler = stateUpdateHandler
        listener.newTransportConnectionHandler = proteanListenerNewConnectionHandler
        listener.start(queue: queue)
    }
    
    public func cancel()
    {
        listener.cancel()
        
        if let stateUpdate = stateUpdateHandler
        {
            stateUpdate(NWListener.State.cancelled)
        }
    }
    
    //MARK: Protean
    
    func proteanify(connection: Connection) -> ProteanConnection?
    {
        return ProteanConnection(connection: connection, config: self.proteanConfig, using: .udp)
    }
    
    func proteanListenerNewConnectionHandler(newConnection: Connection)
    {
        guard let proteanConnection = proteanify(connection: newConnection)
        else
        {
            print("Unable to convert new connection to a Protean connection.")
            return
        }
        
        self.newTransportConnectionHandler?(proteanConnection)
        //self.newConnectionHandler(proteanConnection)
    }
    
}

enum ListenerError: Error
{
    case invalidPort
    case initializationError
}
