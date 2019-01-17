//
//  ViewController.swift
//  multipeer1128
//
//  Created by Betty on 2018/11/28.
//  Copyright © 2018 Betty. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var isAdvertising: Bool!
    
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var peerTableView: UITableView!
    
 
    @IBAction func startStopSwitch(_ sender: AnyObject) {
        let actionSheet = UIAlertController(title: "", message: "Change Visibility", preferredStyle: UIAlertController.Style.actionSheet)
        
        var actionTitle: String
        if isAdvertising == true {
            actionTitle = "Make me invisible to others"
        }
        else {
            actionTitle = "Make me visible to others"
        }
        
        let visibilityAction : UIAlertAction = UIAlertAction(title: actionTitle, style: UIAlertAction.Style.default) { (alertAction) -> Void in
            if self.isAdvertising == true {
                self.appDelegate.mpcManager.advertiser?.stopAdvertisingPeer()
            }
            else {
                self.appDelegate.mpcManager.advertiser?.startAdvertisingPeer()
            }
            
            self.isAdvertising = !self.isAdvertising
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { (alertAction) -> Void in
            
        }
        
        actionSheet.addAction(visibilityAction)
        actionSheet.addAction(cancelAction)
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        peerTableView.delegate = self
        peerTableView.dataSource = self
        
        // Set the ViewController as the delegate of the MPCManager class.
        appDelegate.mpcManager.delegate = self
        
        appDelegate.mpcManager.browser?.startBrowsingForPeers()
        
        appDelegate.mpcManager.advertiser?.startAdvertisingPeer()
        
        //Set its value to true, meaning that the device is currently advertising itself.
        isAdvertising = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: UITableView related method implementation
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return appDelegate.mpcManager.foundPeers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "idCellPeer") as! UITableViewCell
        cell.textLabel?.text = appDelegate.mpcManager.foundPeers[indexPath.row].displayName
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPeer = appDelegate.mpcManager.foundPeers[indexPath.row] as MCPeerID
        
        appDelegate.mpcManager.browser.invitePeer(selectedPeer, to: appDelegate.mpcManager.session, withContext: nil, timeout: 20)
    }
    
}

extension ViewController: MPCManagerDelegate {
    
    // Refresh the tableview
    func foundPeer() {
        
        peerTableView.reloadData()
        
    }
    
    // Refresh the tableview
    func lostPeer() {
        
        peerTableView.reloadData()
        
    }
    
    //Reply to the inviter.
    func unvitationWasReceived(fromPeer: String) {
        
        let alert = UIAlertController(title: "", message: "\(fromPeer) wants to chat with you.", preferredStyle: UIAlertController.Style.alert)
        
        let acceptAction: UIAlertAction = UIAlertAction(title: "Accept", style: UIAlertAction.Style.default) { (alertAction) -> Void in
            self.appDelegate.mpcManager.invitationHandler(true, self.appDelegate.mpcManager.session)
        }
        
        let declineAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { (alertAciton) -> Void in
            self.appDelegate.mpcManager.invitationHandler(false, nil)
        }
        
        alert.addAction(acceptAction)
        alert.addAction(declineAction)
        
        OperationQueue.main.addOperation { () -> Void in
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func connectedWithPeer(peerID: MCPeerID) {
        OperationQueue.main.addOperation { () -> Void in
            self.performSegue(withIdentifier: "idSegueChat", sender: self)
        }
    }
}
