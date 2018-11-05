import Network
import Transport
import Foundation

print("\nI'm here to listen!")

let portString = CommandLine.arguments[0]
var lock: DispatchGroup
let routingController = RoutingController()
lock = DispatchGroup.init()

lock.enter()
routingController.startListening(onPort: portString, proteanEnabled: true)
lock.wait()


