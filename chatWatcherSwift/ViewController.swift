//
//  ViewController.swift
//  chatWatcherSwift
//
//  Created by Douglas Carmichael on 10/22/16.
//  Copyright © 2016 Douglas Carmichael. All rights reserved.
//

import Cocoa
import Starscream

class ViewController: NSViewController, WebSocketDelegate, NSUserNotificationCenterDelegate {
//    func websocketDidConnect(socket: WebSocketClient) {
//        <#code#>
//    }
//
//    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
//        <#code#>
//    }
//
//    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
//        <#code#>
//    }
//
//    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
//        <#code#>
//    }
//

    @IBOutlet var myTextView: NSTextView!
    @objc var socket = WebSocket(url: URL(string: "wss://irc-ws.chat.twitch.tv:443")!)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        socket.delegate = self
        NSUserNotificationCenter.default.delegate = self
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

    @IBAction func hiStimpy(_sender: AnyObject) {
//        sendChannelMessage(ourMessage: "Hello @Talk2MeGooseman from dcarmich's chat watcher in Swift!");
        
    }
    @objc func showNotice(ourNoticeText: String)
    {
        let ourNotifier = NSUserNotification.init()
        ourNotifier.title = "chatWatcherSwift"
        ourNotifier.informativeText = ourNoticeText
        ourNotifier.soundName = NSUserNotificationDefaultSoundName
        ourNotifier.hasActionButton = true
        NSUserNotificationCenter.default.deliver(ourNotifier)

    }
    func websocketDidConnect(socket: WebSocketClient) {
        let defaultAuthKey = UserDefaults.standard.string(forKey: "twitchAuthKey") ?? "g89moa2glyhye6gy6vyy9da2ltgmy5"
       let ourNickname = UserDefaults.standard.string(forKey: "twitchNickname") ?? "dcarmich"
      let ourChannel = UserDefaults.standard.string(forKey: "twitchChannel") ?? "professorbroman"
        if (defaultAuthKey != "nullKey") {
            socket.write(string: "CAP REQ :twitch.tv/tags twitch.tv/commands twitch.tv/membership")
            socket.write(string: "PASS oauth:" + defaultAuthKey)
            socket.write(string: "NICK " + ourNickname)
            socket.write(string: "JOIN #" + ourChannel)
            
            // Notify the user we're connected
            showNotice(ourNoticeText: "Connected to channel: " + ourChannel)
        } else {
            print("unable to connect: Twitch OAuth key invalid")
        }
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        if let e = error {
            print("websocket is disconnected: \(e.localizedDescription)")
        } else {
            print("websocket disconnected")
        }
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
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
                    if (tmiName.count > 0)
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
                
                // Proof of concept user-notification code
                let userToNotify = "deadpoolyplays"
                let userNotifyString = "@" + userToNotify.lowercased()
                let ourMessage = privMsg[privMsg.index(privMsg.startIndex, offsetBy: 1)..<privMsg.endIndex]
                let msgString = NSString(format: "%@: %@", displayedName, ourMessage as CVarArg)
                let msgViewString = NSString(format: "%@%@", oldString, msgString)
                if ourMessage.lowercased().range(of: userNotifyString) != nil {
                    showNotice(ourNoticeText: msgString as String)
                }
                myTextView.string = msgViewString as String
                myTextView.scrollToEndOfDocument(self)
            }
        }
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        print("Received data: \(data.count)")
        
    }
    
    func sendChannelMessage(ourMessage: String)
    {
     //   let ourChannel = UserDefaults.standard.string(forKey: "twitchChannel") ?? "stimpy3d"
        let ourChannel = "talk2megooseman"
        let msgString = NSString(format: "PRIVMSG #%@ :%@", ourChannel, ourMessage)
        print("Message sent: \(msgString)")
        socket.write(string: msgString as String)
    }
    
    func getMsgParamValue(messageInfo: String) -> String {
        let messageParam = messageInfo.components(separatedBy: "=")
        return messageParam[1]
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
 
    @IBAction func disconnectTwitch(_ sender: AnyObject) {
        
        socket.disconnect()
    }
    
    
}

