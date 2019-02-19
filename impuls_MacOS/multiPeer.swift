//
//  multiPeer.swift
//  impuls_MacOS
//
//  Created by Omar Peracha on 12/02/2019.
//  Copyright © 2019 Omar Peracha. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol AudioServiceDelegate {
    
    func connectedDevicesChanged(manager : AudioService, connectedDevices: [String])
    func distanceChanged(manager : AudioService, distance: String)
    
}

class AudioService : NSObject {
    
    var entryDict = ["Omar Peracha’s iPhone": false]
    
    var nearbyPeers = [MCPeerID]()
    
    // Service type must be a unique string, at most 15 characters long
    // and can contain only ASCII lowercase letters, numbers and hyphens.
    private let audioServiceType = "impuls-ios"
    
    var delegate : AudioServiceDelegate?
    
    private let myPeerId = MCPeerID(displayName: Host.current().name ?? "Omar's MacBook")
    
    private let serviceAdvertiser : MCNearbyServiceAdvertiser
    let serviceBrowser : MCNearbyServiceBrowser
    
    override init() {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: audioServiceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: audioServiceType)
        
        super.init()
        
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
        
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    lazy var session : MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        return session
    }()
    
    func send(distance : String) {
        NSLog("%@", "sendDistance: \(distance) to \(session.connectedPeers.count) peers")
        
        if session.connectedPeers.count > 0 {
            do {
                try self.session.send(distance.data(using: .utf8)!, toPeers: session.connectedPeers, with: .reliable)
            }
            catch let error {
                NSLog("%@", "Error for sending: \(error)")
            }
        }
        
    }
    
}

extension AudioService : MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        for i in 0 ..< nearbyPeers.count {
            if nearbyPeers[i].displayName == peerID.displayName {
                nearbyPeers.remove(at: i)
                break
            }
        }
        nearbyPeers.append(peerID)
        if entryDict[peerID.displayName] ?? false {
            invitationHandler(true, self.session)
        }
    }
    
}

extension AudioService : MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        NSLog("%@", "foundPeer: \(peerID)")
        nearbyPeers.append(peerID)
        if entryDict[peerID.displayName] ?? false {
            NSLog("%@", "invitePeer: \(peerID)")
            browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)}
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "lostPeer: \(peerID)")
    }
    
}

extension AudioService : MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state.rawValue)")
        self.delegate?.connectedDevicesChanged(manager: self, connectedDevices:
            session.connectedPeers.map{$0.displayName})
        if state.rawValue == 0 {
            //conductor.destroyUser(withName: peerID.displayName)
            conductor.vc!.lostPeer(ID: peerID.displayName)
        } else if state.rawValue == 2 {
            if entryDict[peerID.displayName] ?? false {
                
                conductor.setup()
                var newUser = true
                for user in conductor.users{
                    if user.name == peerID.displayName {
                        newUser = false
                    }
                }
                if newUser {
                    conductor.initUser(name: peerID.displayName)
                }
                conductor.vc!.newPeer(ID: peerID.displayName)
                
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        //NSLog("%@", "didReceiveData: \(data)")
        let str = String(data: data, encoding: .utf8)!
        self.delegate?.distanceChanged(manager: self, distance: str)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveStream")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        NSLog("%@", "didStartReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        NSLog("%@", "didFinishReceivingResourceWithName")
    }
    
}

