//
//  RoutingController.swift
//  ProteanSwiftServer
//
//  Created by Adelita Schule on 9/7/18.
//
import Network
import Protean
import ProteanSwift
import Transport

public class RoutingController: NSObject
{
    let wireGuardServerIPString = ""
    let wireGuardServerPort: UInt16 = 51820
    var conduitCollection = ConduitCollection()
    var proteanEnabled = true
    
    public func startListening(onPort portString: String, proteanEnabled: Bool)
    {
        guard let port = NWEndpoint.Port(rawValue: wireGuardServerPort)
        else
        {
            print("Unable to start listening, unable to resolve port.")
            return
        }
        
        self.proteanEnabled = proteanEnabled
        if proteanEnabled
        {
            do
            {
                let proteanListener = try ProteanListener(using: .udp, config: sampleProteanConfig(), on: port)
                
                proteanListener.stateUpdateHandler = debugListenerStateUpdateHandler
                proteanListener.newTransportConnectionHandler =
                {
                    [weak self] (proteanConnection) in
                    
                    if let strongSelf = self
                    {
                        strongSelf.listenerConnectionHandler(newConnection: proteanConnection, port: port)
                    }
                }
                
                proteanListener.start(queue: proteanListener.queue!)
                print("\nCurrently listening with Protean.\n")
            }
            catch
            {
                print("\nUnable to start listening with Protean.\n")
            }
        }
        else
        {
            do
            {
                let listener = try NWListener(using: .udp, on: port)
                listener.stateUpdateHandler = debugListenerStateUpdateHandler
                listener.newTransportConnectionHandler =
                {
                    [weak self] (plainConnection) in
                    
                    if let strongSelf = self
                    {
                        strongSelf.listenerConnectionHandler(newConnection: plainConnection, port: port)
                    }
                }
            }
            catch
            {
                print("\nUnanble to start listening on plain mode.\n")
            }
            
            
        }
    }
    
    func transfer(from receiveConnection: Connection, to sendConnection: Connection, transferID: Int)
    {
        receiveConnection.receive
        {
            (maybeReceiveData, maybeReceiveContext, receivedComplete, maybeReceiveError) in
            
            if let receiveError = maybeReceiveError
            {
                print("Received an error on receiveConnection.recieve: \(receiveError)")
                self.stopTransfer(for: transferID)
                return
            }
            
            if let receiveData = maybeReceiveData
            {
                sendConnection.send(content: receiveData,
                                    contentContext: .defaultMessage,
                                    isComplete: receivedComplete,
                                    completion: NWConnection.SendCompletion.contentProcessed(
                    
                { (maybeSendError) in
                    
                    if let sendError = maybeSendError
                    {
                        print("\nReceived a send error: \(sendError)\n")
                        self.stopTransfer(for: transferID)
                        return
                    }
                    else
                    {
                        self.transfer(from: receiveConnection, to: sendConnection, transferID: transferID)
                    }
                }))
            }
        }
        
    }
    
    func stopTransfer(for clientID: Int)
    {
        guard let conduit = conduitCollection.getConduit(withID: clientID)
        else
        {
            print("No transfer to stop, no conduit found for clientID: \(clientID)")
            return
        }
        
        // Call Cancel on both connections
        conduit.wireGuardConnection.cancel()
        conduit.transportConnection.cancel()
        
        // Remove connections from ClientConnectionController dict.
        conduitCollection.removeConduit(withID: clientID)
    }
    
    func debugConnectionStateUpdateHandler(newState: NWConnection.State)
    {
        switch newState
        {
            case .cancelled:
                print("\nWireGuard server connection canceled.")
            case .failed(let networkError):
                print("\nWireGuard server connection failed with error:  \(networkError)")
            case .preparing:
                print("\nPreparing connection to Wireguard server.")
            case .setup:
                print("\nWireGuard connection in setup phase.")
            case .waiting(let waitError):
                print("\n⏳\nWireguard connection waiting with error: \(waitError)")
            case .ready:
                print("\nWireGuard Connection is Ready")
        }
    }
    
    
    func debugListenerStateUpdateHandler(newState: NWListener.State)
    {
        switch newState
        {
            case .ready:
                print("\nListening...\n")
            case .failed(let error):
                print("\nListener failed with error: \(error)\n")
            default:
                print("\nReceived unexpected state: \(newState)\n")
                break
        }
    }
    
    func listenerConnectionHandler(newConnection: Connection, port: NWEndpoint.Port)
    {
        guard let ipv4Address = IPv4Address(wireGuardServerIPString)
            else
        {
            print("Unable to resolve ipv4 address for WireGuard server.")
            return
        }
        
        let host = NWEndpoint.Host.ipv4(ipv4Address)
        let connectionFactory = NetworkConnectionFactory(host: host, port: port)
        let maybeConnection = connectionFactory.connect(using: .udp)
        
        guard var wgConnection = maybeConnection
            else
        {
            print("Unable to create connection to the WireGuard server.")
            return
        }
        
        wgConnection.stateUpdateHandler = debugConnectionStateUpdateHandler
        
        let transferID = conduitCollection.addConduit(wireGuardConnection: wgConnection, transportConnection: newConnection)
        
        let transferQueue1 = DispatchQueue(label: "Transfer Queue 1")
        
        transferQueue1.async
        {
            self.transfer(from: newConnection, to: wgConnection, transferID: transferID)
        }
        
        let transferQueue2 = DispatchQueue(label: "Transfer Queue 2")
        
        transferQueue2.async
        {
            self.transfer(from: wgConnection, to: newConnection, transferID: transferID)
        }
    }
    
    
    
}




