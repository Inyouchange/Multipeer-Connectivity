//
//  ChatService.swift
//  testMultipeer1123
//
//  Created by Betty on 2018/11/23.
//  Copyright © 2018 Betty. All rights reserved.
//

import Foundation
import UIKit
import MultipeerConnectivity

//Declare a delegate protocol ColorServiceDekegate to notify the UI about service events
protocol ChatServiceDelegate {
    
    func mcManager(manager: ChatService, session: MCSession, didReceive data: Data, from peer: MCPeerID)
    func mcManager(manager: ChatService, session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState)
    
}

class ChatService: NSObject {
    static let sharedInstance = ChatService()
    /*Service type must be a unique string, at most 15 characters long
     and can contain only ASCII lowercase letters, numbers and hyphens.*/
    private let serviceType = "example-chat"
    private let timeoutInterval = 10.0
    /*Create a MCNearbyServiceBrowser to scan for the advertised service on other devices.
     Implement the MCNearbyServiceBrowserDelegate protocol and log all the browser events*/
    private var browser: MCNearbyServiceBrowser?
    private var advertiser: MCNearbyServiceAdvertiser?
    
    //Sending and accepting invitations
    private lazy var session: MCSession = {
        let session = MCSession(peer: self.ownID, securityIdentity: nil, encryptionPreference: .optional)
        session.delegate = self
        return session
    }()
    
    private lazy var ownID: MCPeerID = {
        return MCPeerID(displayName: UIDevice.current.name)
    }()
    
    //Declare a delegate for the ChatService
    var delegate: ChatServiceDelegate?
    
    var connectedPeers: [MCPeerID] {
        return session.connectedPeers
    }
    
    deinit {
        self.session.disconnect()
        self.stopManager()
    }
    
    override init() {
        super.init()
    }
    
    func startManager() {
        self.browser = MCNearbyServiceBrowser(peer: self.ownID, serviceType: self.serviceType)
        self.advertiser = MCNearbyServiceAdvertiser(peer: self.ownID, discoveryInfo: nil, serviceType: self.serviceType)
        
        self.browser?.delegate = self
        self.advertiser?.delegate = self
        
        self.browser?.startBrowsingForPeers()
        self.advertiser?.startAdvertisingPeer()
        
    }
    
    func stopManager() {
        browser?.stopBrowsingForPeers()
        advertiser?.stopAdvertisingPeer()
        browser?.delegate = nil
        advertiser?.delegate = nil
        browser = nil
        advertiser = nil
    }
    
    //Send data
    func send(data: Data) {
        send(data: data, peers: connectedPeers)
    }
    
    func send(data: Data, peer: MCPeerID) {
        let peers = [peer]
        send(data: data, peers: peers)
    }
    
    func send(data: Data, peers: [MCPeerID]) {
        if peers.count > 0 {
            do {
                try session.send(data, toPeers: peers, with: .reliable)
            } catch let error {
                print(error)
            }
        }
    }
    
}

extension ChatService: MCNearbyServiceBrowserDelegate {

    //Invites any peer automatically. The MCBrowserViewController class could be used to scan for peers and invite them manually.
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        
        if peerID == ownID {
            return
        }
        
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: timeoutInterval)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "lostPeer: \(peerID)")
    }
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }
}

extension ChatService: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        
        //When receive an invitation, accept it by calling the invitionHandler block with true
        if peerID != ownID {
            invitationHandler(true, self.session)
        }
        else {
            invitationHandler(false, nil)
        }
    }
}

extension ChatService: MCSessionDelegate {
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.delegate?.mcManager(manager: self, session: session, didReceive: data, from: peerID)
            NSLog("%@", "didReceiveData: (data)")
        }
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            /*Extend the implementation of the MCSessionDelegate protocol
             When the connected devices change or when data is received*/
            self.delegate?.mcManager(manager: self, session: session, peer: peerID, didChange: state)
        }
        NSLog("%@", "peer \(peerID) didChangeState: \(state.rawValue)")
    }
    
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        NSLog("%@", "didFinishReceivingResourceWithName")
    }
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveStream")
    }
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        NSLog("%@", "didStartReceivingResourceWithName")
    }
}
