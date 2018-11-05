//
//  ProteanSwiftServerTests.swift
//  ProteanSwiftServerTests
//
//  Created by Adelita Schule on 10/24/18.
//

import XCTest
import Network
import INI
import Transport
import Datable

import ProteanSwiftServer

class ProteanSwiftServerTests: XCTestCase
{
    var portString = ""

    override func setUp()
    {
        super.setUp()
        
        do
        {
            let config = try parseINI(filename: "/Users/Lita/tempWireGuard/utun9server.conf")
            
            print(config.sections)
            
            guard let listenPortString = config["Interface"]?["ListenPort"]
                else
            {
                print("\nUnable to get endpoint from config file.\n")
                return
            }
            
            portString = listenPortString
        }
        catch (let error)
        {
            print("\nUnable to locate wireguard config file.")
            print("Received an error: \(error)\n")
        }
    }
    
    func testListenWithoutProtean()
    {
        var lock: DispatchGroup
        let routingController = RoutingController()
        lock = DispatchGroup.init()
        
        lock.enter()
        routingController.startListening(onPort: portString, proteanEnabled: false)
        print("\nListening on port \(portString)\n")
        lock.wait()
    }
    
    func testNetworkUDPConnectionSendReceive()
    {
        guard let portUInt = UInt16("1234"), let port = NWEndpoint.Port(rawValue: portUInt)
            else
        {
            print("Unable to resolve port for test")
            XCTFail()
            return
        }
        
        guard let ipv4Address = IPv4Address("192.168.129.5")
            else
        {
            print("Unable to resolve ipv4 address for test")
            XCTFail()
            return
        }
        
        let connected = expectation(description: "Connected to the server.")
        let wrote = expectation(description: "Wrote data to the server.")
        let host = NWEndpoint.Host.ipv4(ipv4Address)
        let connectionFactory = NetworkConnectionFactory(host: host, port: port)
        let maybeConnection = connectionFactory.connect(using: .udp)
        
        XCTAssertNotNil(maybeConnection)
        
        guard var connection = maybeConnection
            else
        {
            return
        }
        
        connection.stateUpdateHandler =
        {
            (newState) in
            
            print("CURRENT STATE = \(newState))")
            
            switch newState
            {
            case .ready:
                print("\n🚀 open() called on tunnel connection  🚀\n")
                let message = "Hello Hello"
                connected.fulfill()
                
                connection.send(content: message.data(using: String.Encoding.ascii),
                                contentContext: .defaultMessage,
                                isComplete: true,
                                completion: NWConnection.SendCompletion.contentProcessed(
                {
                    (error) in
                    
                    if error == nil
                    {
                        wrote.fulfill()
                        print("\nNo ERROR\n")
                    }
                        
                    else
                    {
                        print("\n⛑  RECEIVED A SEND ERROR: \(String(describing: error))\n")
                        XCTFail()
                    }
                }))
                
            case .cancelled:
                print("\n🙅‍♀️  Connection Canceled  🙅‍♀️\n")
                
            case .failed(let error):
                print("\n🐒💨  Connection Failed  🐒💨\n")
                print("⛑  Failure Error: \(error.localizedDescription)")
                XCTFail()
                
            default:
                print("\n🤷‍♀️  Unexpected State: \(newState))  🤷‍♀️\n")
            }
        }
        
        maybeConnection?.start(queue: DispatchQueue(label: "TestQueue"))
        
        waitForExpectations(timeout: 30)
        { (maybeError) in
            if let error = maybeError
            {
                print("Expectation completed with error: \(error.localizedDescription)")
            }
        }
    }


}
