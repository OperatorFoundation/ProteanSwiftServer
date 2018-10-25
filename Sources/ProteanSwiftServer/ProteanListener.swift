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
    public var debugDescription: String = "[UDPListener]"
    
    public var newConnectionHandler: ((NWConnection) -> Void)?
    
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
    
    func proteanify(connection: Connection) -> ProteanConnection?
    {
        // Protean Transform
        let proteanTransformer = Protean(config: self.proteanConfig)
        return ProteanConnection(connection: connection, config: self.proteanConfig, using: .udp)
    }
    
    public func start(queue: DispatchQueue)
    {
        // Start the listener
        listener.stateUpdateHandler = stateUpdateHandler
        listener.newConnectionHandler = newConnectionHandler
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
}

enum ListenerError: Error
{
    case invalidPort
    case initializationError
}
