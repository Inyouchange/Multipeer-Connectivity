//
//  ChatViewController.swift
//  multipeer1128
//
//  Created by Betty on 2018/11/28.
//  Copyright © 2018 Betty. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    var messagesArray: [Dictionary<String, String>] = []
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var textChat: UITextField!
    
    @IBOutlet weak var chatTableView: UITableView!
    
    
    @IBAction func endChat(_ sender: AnyObject) {
        let messageDictionary: [String: String] = ["message": "_end_chat_"]
        if appDelegate.mpcManager.sendData(dictionaryWithData: messageDictionary, toPeer: appDelegate.mpcManager.session.connectedPeers[0] as MCPeerID) {
            self.dismiss(animated: true, completion: { () -> Void in
                self.appDelegate.mpcManager.session.disconnect()
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        chatTableView.delegate = self
        chatTableView.dataSource = self
        
        chatTableView.estimatedRowHeight = 60.0
        chatTableView.rowHeight = UITableView.automaticDimension
        
        textChat.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: "handleMPCReceivedDataWithNotification:", name: NSNotification.Name(rawValue: "receivedMPCDataNotification"), object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: UITableView related method implementation
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messagesArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCell(withIdentifier: "idCell") as! UITableViewCell
        let currentMessage = messagesArray[indexPath.row] as Dictionary<String, String>
        if let sender = currentMessage["sender"] {
            var senderLabelText: String
            var senderColor: UIColor
            
            if sender == "self" {
                senderLabelText = "I said:"
                senderColor = UIColor.purple
            }
            else {
                senderLabelText = sender + " Said:"
                senderColor = UIColor.gray
            }
            
            cell.detailTextLabel?.text = senderLabelText
            cell.detailTextLabel?.textColor = senderColor
            
        }
        
        if let message = currentMessage["message"] {
            cell.textLabel?.text = message
        }
        return cell
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        let messageDictionary: [String: String] = ["message": textField.text!]
        
        if appDelegate.mpcManager.sendData(dictionaryWithData: messageDictionary, toPeer: appDelegate.mpcManager.session.connectedPeers[0] as MCPeerID) {
            
            var dictionary: [String: String] = ["sender": "self", "message": textField.text!]
            messagesArray.append(dictionary)
            
            self.updateTableView()
        }
        else {
            print("Could not send data")
        }
        
        textField.text = ""
        
        return true
    }
    
    func updateTableView() {
        
        
        self.chatTableView.reloadData()
        
        if self.chatTableView.contentSize.height > self.chatTableView.frame.size.height {
            chatTableView.scrollToRow(at: IndexPath(row: messagesArray.count - 1, section: 0), at: UITableView.ScrollPosition.bottom, animated: true)
        }
    }
    
    func handleMPCReceivedDataWithNotification(notification: NSNotification) {
        // Get the dictionary containing the data and the source peer from the notificaiton.
        let receivedDataDictionary = notification.object as! Dictionary<String, AnyObject>
        
        // "Extract" the data and the source peer from the received dictionary.
        let data = receivedDataDictionary["data"] as? NSData
        let fromPeer = receivedDataDictionary["fromPeer"] as! MCPeerID
        
        // Convert the data(NSData) into a Dictionary object.
        let dataDictionary = NSKeyedUnarchiver.unarchiveObject(with: data! as Data) as! Dictionary<String, String>
        
        // Check if there;s an entry with the "message" key.
        if let message = dataDictionary["message"] {
            //Make sure that the message is other than "end chat"
            if message != "_end_chat_" {
                // Create a new dictionary and set the sender and the received message to it.
                var  messageDictionary: [String: String] = ["sender": fromPeer.displayName, "message": message]
                
                // Add this dictionary to the messagesArray array.
                messagesArray.append(messageDictionary)
                
                // Reload the tableview data and scroll to the bottom using the main thread.
                OperationQueue.main.addOperation({ () -> Void in
                    self.updateTableView()
                })
            }
            else {
                /* Received the "_end_chat_" message
                   Show an alert view to the user.*/
                let alert = UIAlertController(title: "", message: "\(fromPeer.displayName) ended this chat.", preferredStyle: UIAlertController.Style.alert)
                
                let doneAction: UIAlertAction = UIAlertAction(title: "Okay", style: UIAlertAction.Style.default) { (alertAction) -> Void in
                    self.appDelegate.mpcManager.session.disconnect()
                    self.dismiss(animated: true, completion: nil)
                }
                
                alert.addAction(doneAction)
                
                OperationQueue.main.addOperation({ () -> Void in
                    self.present(alert, animated: true, completion: nil)
                })
            }
        }
    }
}
