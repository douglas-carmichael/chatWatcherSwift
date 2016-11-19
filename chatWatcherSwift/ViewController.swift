//
//  ViewController.swift
//  chatWatcherSwift
//
//  Created by Douglas Carmichael on 10/22/16.
//  Copyright © 2016 Douglas Carmichael. All rights reserved.
//

import Cocoa
import Starscream

class ViewController: NSViewController, WebSocketDelegate {

    @IBOutlet var myTextView: NSTextView!
    var socket = WebSocket(url: URL(string: "wss://irc-ws.chat.twitch.tv:443")!)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        socket.delegate = self
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func connectTwitch(_ sender: AnyObject) {

        socket.connect()

    }

    func websocketDidConnect(socket: WebSocket) {
        print("websocket is connected")
        let authKey = ""
        let ourNickname = "dcarmich"
        socket.write(string: "CAP REQ :twitch.tv/tags twitch.tv/commands twitch.tv/membership")
        socket.write(string: "PASS oauth:" + authKey)
        socket.write(string: "NICK " + ourNickname)
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        if let e = error {
            print("websocket is disconnected: \(e.localizedDescription)")
        } else {
            print("websocket disconnected")
        }
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        if text.range(of:"PING") != nil {
            socket.write(string: "PONG :tmi.twitch.tv")
        }
        else
        {
            let splitString = text.components(separatedBy: " ")
            let oldString = myTextView.string
            if text.range(of: "PRIVMSG") != nil
            {
                /*
                 Example of a split PRIVMSG message:
 ["@badges=;color=#FF0000;display-name=t4nkd0g;emotes=;id=7576e97a-a1da-4ade-9243-a52cee145cc9;mod=0;room-id=26490481;sent-ts=1477271840517;subscriber=0;tmi-sent-ts=1477271840638;turbo=0;user-id=69045114;user-type=", ":t4nkd0g!t4nkd0g@t4nkd0g.tmi.twitch.tv", "PRIVMSG", "#summit1g", ":lol\r\n"]
                 Example of a special case:
 ["@badges=subscriber/3;color=#CC00B1;display-name=;emotes=;id=22eba232-8b6d-4f4f-99c6-6d192d31c49f;mod=0;room-id=39158791;sent-ts=1477418613794;subscriber=1;tmi-sent-ts=1477418615033;turbo=0;user-id=20055743;user-type=", ":captain_elsewhere!captain_elsewhere@captain_elsewhere.tmi.twitch.tv", "PRIVMSG", "#professorbroman", ":exclusive", "mask", "from", "last", "year", "racergi\r\n"]
                */
                var displayedName: String = ""
                let stringCount = (splitString.count)-1
                let userString = splitString[1]
                let userSeparator = userString[userString.index(userString.startIndex, offsetBy: 1)..<userString.endIndex]
                _ = (userSeparator.components(separatedBy: "!")[0])
                // Grab the information about the message
                let messageData = splitString[0].components(separatedBy: ";")
                // [0]	String	":twitchnotify!twitchnotify@twitchnotify.tmi.twitch.tv"	
                if (messageData.count >= 2)
                {
                    let tmiName = getMsgParamValue(messageInfo: messageData[2])
                    if (tmiName.characters.count > 0)
                    {
                        displayedName = tmiName
                    }
                    else
                    {
                        displayedName = (userSeparator.components(separatedBy: "!")[0])
                    }
                }
                else
                {
                    displayedName = (userSeparator.components(separatedBy: "!")[0])
                }
                var privMsg = ""
                for i in 4...stringCount {
                    privMsg += "\(splitString[i]) "
                }
                let newString = NSString(format: "%@%@: %@", oldString!,displayedName,
                                         privMsg[privMsg.index(privMsg.startIndex, offsetBy: 1)..<privMsg.endIndex])
                myTextView.string = newString as String
                myTextView.scrollToEndOfDocument(self)
            }
        }
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        print("Received data: \(data.count)")
        
    }
    
    func getMsgParamValue(messageInfo: String) -> String {
        let messageParam = messageInfo.components(separatedBy: "=")
        return messageParam[1]
    }
    
    
    @IBAction func goChannel(_ sender: NSButton) {
        let channel = "professorbroman"
        socket.write(string: "JOIN #" + channel)
    }
    
    @IBAction func disconnectTwitch(_ sender: AnyObject) {
        
        socket.disconnect()
    }
    
    
}

