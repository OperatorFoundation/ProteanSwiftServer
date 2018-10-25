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

class RoutingController: NSObject
{
    let wireGuardServerIPString = ""
    let wireGuardServerPort: UInt16 = 51820
    var clientController = ClientConnectionController()
    
    func startListening(portString: String)
    {
        guard let port = NWEndpoint.Port(rawValue: wireGuardServerPort)
        else
        {
            print("Unable to start listening, unable to resolve port.")
            return
        }
        
        do
        {
            let proteanListener = try ProteanListener(using: .udp, config: sampleProteanConfig(), on: port)
            
            proteanListener.stateUpdateHandler =
                {
                    (newState) in
                    
                    switch newState
                    {
                    case .ready:
                        print("Listening on port \(port)")
                    case .failed(let error):
                        print("Listener failed with error: \(error)")
                    default:
                        print("Received unexpected state: \(newState)")
                        break
                    }
            }
            
            proteanListener.newConnectionHandler =
            {
                [weak self] (proteanConnection) in
                
                var currentPort = port
                
                if let strongSelf = self
                {
                    
                    strongSelf.clientController.addConnection(connection: proteanConnection)
                    
                    var port: NWEndpoint.Port
                    if let rawPort = UInt16(portString), let userPort = NWEndpoint.Port(rawValue: rawPort)
                    {
                        currentPort = userPort
                    }

                    
                    guard let ipv4Address = IPv4Address(strongSelf.wireGuardServerIPString)
                        else
                    {
                        print("Unable to resolve ipv4 address for WireGuard server.")
                        return
                    }
                    let host = NWEndpoint.Host.ipv4(ipv4Address)
                    let connectionFactory = NetworkConnectionFactory(host: host, port: currentPort)
                    let maybeConnection = connectionFactory.connect(using: .udp)
                    
                    guard var wgConnection = maybeConnection
                        else
                    {
                        print("Unable to create connection to the WireGuard server.")
                        return
                    }
                    
                    wgConnection.stateUpdateHandler =
                    {
                        (newState) in
                        
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
                    
                    //FIXME: First call to transfer needs to be async
                    strongSelf.transfer(from: proteanConnection, to: wgConnection)
                    
                    strongSelf.transfer(from: wgConnection, to: proteanConnection)
                }
            }
            
            proteanListener.start(queue: proteanListener.queue!)
            print("\nCurrently listening.\n")
        }
        catch
        {
            print("\nUnable to start listening.\n")
        }
    }
    
    func transfer(from receiveConnection: Connection, to sendConnection: Connection)
    {
        //FIXME: Handle error/nil cases
        
        /*
         wgConnection.receive(completion:
         {
         (maybeWGData, maybeWGContext, receiveComplete, maybeWGError) in
         
         if let wgData = maybeWGData
         {
         let transformedWGDatas = proteanTransformer.transform(buffer: wgData)
         if !transformedWGDatas.isEmpty, let transformedWGData = transformedWGDatas.first
         {
         connection.send(content: transformedWGData,
         contentContext: .defaultMessage,
         isComplete: true,
         completion: NWConnection.SendCompletion.idempotent)
         }
         
         }
         
         if let wgError = maybeWGError
         {
         print("Received error receiving from WireGuard server: \(wgError)")
         }
         })
         */
        receiveConnection.receive
        {
            (maybeReceiveData, maybeReceiveContext, receivedComplete, maybeReceiveError) in
            
            if let receiveData = maybeReceiveData
            {
                sendConnection.send(content: receiveData, contentContext: .defaultMessage, isComplete: receivedComplete, completion: NWConnection.SendCompletion.contentProcessed(
                    
                { (maybeSendError) in
                    
                    if let sendError = maybeSendError
                    {
                        //Stub
                        print("\nReceived a send error: \(sendError)\n")
                        
                    }
                    else
                    {
                        self.transfer(from: receiveConnection, to: sendConnection)
                    }
                }))
            }
        }
    }
}




