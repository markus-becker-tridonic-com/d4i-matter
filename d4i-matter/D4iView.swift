//
//  D4iview.swift
//  constant-light-matter
//
//  Created by Markus Becker on 06.03.22.
//

import Combine
import SwiftUI

import HomeKit
import Matter
import Foundation

class TargetMeasuredValue: ObservableObject {
    @Published public var measuredValue = 0.0
}

class HKHandler : NSObject, HMHomeManagerDelegate {
    let homeManager = HMHomeManager()
    
    var homekitReady = false
    
    var currentDimLevel = 0
    
    var _device: MTRDevice?
    
    override init() {
        super.init()
        homeManager.delegate = self
        print("HK init OK")
    }
//    func homeManagerDidUpdateHomes(_ manager: HMHomeManager)
//    {
//        print("homeManagerDidUpdateHomes")
//        for home in manager.homes {
//            print("Home:\(home.name)")
//        }
//    }
    
    func xpcconninit() -> NSXPCConnection {
        return NSXPCConnection.init()
    }
    
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager)
    {
        print("homeManagerDidUpdateHomes")
        for home in manager.homes {
            print("Home:\(home.name)")
        }
        
        print("authorizationStatus: \(homeManager.authorizationStatus)")
        if homeManager.authorizationStatus.contains(.authorized) {
            // The app is authorized to access home data.
            print("HK auth OK")
            self.homekitReady = true
        }
        
        if homeManager.homes.count > 0 {
            let home = homeManager.homes[0]
            let matterControllerID = home.matterControllerID as NSString

            let remoteDeviceController =
            MTRDeviceController.sharedController(
                withId: matterControllerID,
                xpcConnect: xpcconninit
            )
            
            if home.rooms.count > 0 {
                let room = home.rooms[0]
                if room.accessories.count > 0 {
                    let acc = room.accessories[0]
                    print("accessory name: \(acc.name)")
                
                    if let matterNodeID = acc.matterNodeID {
                        print("accessory nodeid: \(matterNodeID)")
                        
                        _device = MTRDevice.init(
                            nodeID: matterNodeID,
                            deviceController: remoteDeviceController)
                        
                        if let device = _device {
                            print("Device acquired. Reading...");
                            let answer = device.readAttribute(
                                withEndpointID: 1, // light endpoint
                                clusterID: 0x0303, // cluster: energy reporting
                                attributeID: 0x0003, // attrbute active power)
                                params: nil
                            )
                            print("Device answered: \(answer)");
                        }
                    } else {
                        print("Accessory has not matterNodeID")
                    }
                } else {
                    print("No accessory 0")
                }
            } else {
                print("No room 0")
            }
        } else {
            print("No home 0")
        }
    }
}


struct D4iView: View {

    @ObservedObject private var state: TargetMeasuredValue = TargetMeasuredValue()
    
    let queue = DispatchQueue.global(qos: .background)

    var hk = HKHandler()

    var body: some View {
        VStack {
            Label("D4i value", systemImage: "star")
                .font(.title)
                .labelStyle(.titleOnly)
            Label("Measured Value", systemImage: "star")
                .font(.title)
                .labelStyle(.titleOnly)
            Text("\(state.measuredValue, specifier: "%.1f") mW")
                .padding()
        }
    }
    
    init() {
        print("D4iView init")
        scheduleMeasurement()
    }
    
    func scheduleMeasurement() {
        queue.asyncAfter(deadline: .now() + 10) {
            DispatchQueue.main.async {
                measureAndAct()
            }
        }
    }

    func measureAndAct() {
        print("D4iView measureAndAct")
        
        if let device = hk._device {
            print("Device acquired. Reading...");
            let answer = device.readAttribute(
                withEndpointID: 1, // light endpoint
                clusterID: 0x0303, // cluster: energy reporting
                attributeID: 0x0003, // attrbute active power)
                params: nil
            )
            print("Device answered: \(answer)");
            // TODO: calculate the milliWattValue from the answer
            let milliWattValue: Double = 50
            state.measuredValue = milliWattValue
        } else {
            print("No matter device.");
        }

        scheduleMeasurement()
    }
}
