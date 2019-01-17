//
//  MPCManager.swift
//  multipeer1128
//
//  Created by Betty on 2018/11/28.
//  Copyright © 2018 Betty. All rights reserved.
//

import UIKit
import MultipeerConnectivity

protocol MPCManagerDelegate {
    
    func foundPeer()
    
    func lostPeer()
    
    func unvitationWasReceived(fromPeer: String)
    
    func connectedWithPeer(peerID: MCPeerID)
}

class MPCManager: NSObject, MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate {
    
    
    /* Two rules should always follow
        (1) It mustn't be longer than 15 characters
        (2) It can contain only lowercase ASCII characters,numbers.*/
    private let serviceType = "exmultipeer"
    var session: MCSession!
    var peer: MCPeerID!
    var browser: MCNearbyServiceBrowser!
    var advertiser: MCNearbyServiceAdvertiser!
    // Store all the peers that the browser of a device will discover.
    var foundPeers = [MCPeerID]()
    var invitationHandler: ((Bool, MCSession!)->Void)!
    
    var delegate: MPCManagerDelegate?
    
    override init() {
        
        super.init()
        peer = MCPeerID(displayName: UIDevice.current.name)
        
        session = MCSession(peer: peer)
        session.delegate = self
        
        browser = MCNearbyServiceBrowser(peer: peer, serviceType: serviceType)
        browser.delegate = self
        
        advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: serviceType)
        advertiser.delegate = self
        
    }
    
    // Find peer
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        
        //Add the found peer in the foundPeers array
        foundPeers.append(peerID)
        /*Make a call to the foundPeer delegate method of the MPCManagerDelegate protocol
           which will be implemented in the ViewController class*/
        delegate?.foundPeer()
        
    }
    
    // Lost peer
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        for (index, aPeer) in foundPeers.enumerated() {
            if aPeer == peerID {
                foundPeers.remove(at: index)
                break
            }
        }
        
        delegate?.lostPeer()
    }
    
    // Manage any error that may occur and the browsing is unable to be performed.
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print(error.localizedDescription)
    }
    
    // Store the invitation handler.
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        self.invitationHandler = invitationHandler
        delegate?.unvitationWasReceived(fromPeer: peerID.displayName)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print(error.localizedDescription)
    }
    
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
        switch state {
            
        case MCSessionState.connected:
            print("Connected to session: \(session)")
            delegate?.connectedWithPeer(peerID: peerID)
        case MCSessionState.connecting:
            print("Connecting to session: \(session)")
        case MCSessionState.notConnected:
            print("Did not connect to session: \(session)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let dictionary: [String: AnyObject] = ["data": data as AnyObject, "fromPeer": peerID]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "receivedMPCDataNotification"), object: dictionary)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) { }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) { }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) { }
    
   
    func sendData(dictionaryWithData dictionary: Dictionary<String, String>, toPeer targetPeer: MCPeerID) -> Bool {
        
        let dataToSend = NSKeyedArchiver.archivedData(withRootObject: dictionary)
        let peersArray = [MCPeerID]()
        var error: NSError?
        
        do {
            try session.send(dataToSend, toPeers: peersArray, with: MCSessionSendDataMode.reliable)
            
        }catch {
            print(error.localizedDescription)
            return false
        }
        return true
    }
    
}
