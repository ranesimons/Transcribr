//
//  ViewController.swift
//  Transcribr
//
//  Created by Rane Simons on 8/27/21.
//

import Foundation
import UIKit
import AVFoundation
import Speech
import SocketIO

struct SocketMessage: Codable {
    var message: String
    var username: String
}

class SocketParser {

    static func convert<T: Decodable>(data: Any) throws -> T {
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: jsonData)
    }
    
    static func convert<T: Decodable>(datas: [Any]) throws -> [T] {
        return try datas.map { (dict) -> T in
            let jsonData = try JSONSerialization.data(withJSONObject: dict)
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: jsonData)
        }
    }
}

protocol ChatManagerDelegate {
    func didReceiveMessage(message: String)
}

class SocketChatManager {
    
    var delegate: ChatManagerDelegate?
    
    // properties
    let manager = SocketManager(socketURL: URL(string: "ws://localhost:3000")!, config: [.log(false), .compress])
    var socket: SocketIOClient? = nil
//    var originalView:ViewController
    
    // lives
    
    init() {
        setupSocket()
        setupSocketEvents()
        socket?.connect()
    }
    
    func stop() {
        socket?.removeAllHandlers()
    }
    
    // setup
    
    func setupSocket() {
        self.socket = manager.defaultSocket
    }
    
    func setupSocketEvents() {
        socket?.on(clientEvent: .connect) {data, ack in
//            print("Connected")
        }

//        socket?.on("login") { (data, ack) in
//            guard let dataInfo = data.first else { return }
//            if let response: SocketLogin = try? SocketParser.convert(data: dataInfo) {
//                print("Now this chat has \(response.numUsers) users.")
//            }
//
//        }
//
//        socket?.on("user joined") { (data, ack) in
//            guard let dataInfo = data.first else { return }
//            if let response: SocketUserJoin = try? SocketParser.convert(data: dataInfo) {
//                print("User '\(response.username)' joined...")
//                print("Now this chat has \(response.numUsers) users.")
//            }
//        }
        
        socket?.on("new message") { (data, ack) in
//            print("?????????????????????")
//            print(data)
//            print(data.first)
//            print("?????????????????????")
            guard let dataInfo = data.first else { return }
//            print("?????????????????????")
//            print(dataInfo)
//            print(dataInfo)
//            let jsonData = try JSONSerialization.data(withJSONObject: dict)
//            let decoder = JSONDecoder()
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: dataInfo)
//                print("?????????????????????")
//                print(jsonData)
//                print("?????????????????????")
                let decoder = JSONDecoder()
//                print("*********************")
                let result = try decoder.decode(Dictionary<String, String>.self, from: jsonData)
//                print("?????????????????????")
//                print(result)
//                print("?????????????????????")
//                print("?????????????????????")
                let unwrapd = result.first
//                print(unwrapd)
//                print("?????????????????????")
                let theActualMessage:String = unwrapd!.value
//                print(theActualMessage)
//                print("?????????????????????")
//                print(self.delegate)
//                print("?????????????????????")
                self.delegate?.didReceiveMessage(message: theActualMessage)
            } catch {
//                print("naw: \(error)")
            }
        }
    }

    func send(message: String) {
//        print("###########################")
        try socket?.emit("new message", message) {
//            print("uhh")
        }
//        catch {
//            print("hmm")
//        }
//        print("###########################")
    }

}

class ViewController: UIViewController, AVAudioRecorderDelegate, UITableViewDelegate, UITableViewDataSource, ChatManagerDelegate {
    
    var numberOfMessages:Int = 0
    var words:[String] = []
    var recordingSession:AVAudioSession!
    var audioRecorder:AVAudioRecorder!
    var audioPlayer:AVAudioPlayer!
    var chats:SocketChatManager!
    var numberOfRecordings:Int = 0
    @IBOutlet weak var recordAudioLabel: UIButton!
    @IBOutlet weak var seeAudioRecordings: UITableView!
    @IBOutlet var prototypeChatMessages: UITableView!

    @IBAction func recordTheAudio(_ sender: Any) {
        if audioRecorder == nil
        {
            numberOfRecordings += 1
//            let nameOfFile = getFileDirectory().appendingPathComponent("\(numberOfRecordings).mp4a")
            let nameOfFile = getFileDirectory().appendingPathComponent("\(numberOfRecordings).m4a")
            let setting = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 1200, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]

            // Start recordin audio
            do
            {
                audioRecorder = try AVAudioRecorder(url: nameOfFile, settings: setting)
                audioRecorder.delegate = self
                audioRecorder.record()
//                try recordingSession.setCategory(AVAudioSession.CategoryOptions)
                recordAudioLabel.setTitle("End", for: .normal)
            }
            catch
            {
                displayAnAlert(title: "Hmm", message: "Failed To Record")
            }
        }
        else
        {
            audioRecorder.stop()
            audioRecorder = nil
            UserDefaults.standard.set(numberOfRecordings, forKey: "num")
            let sound = getFileDirectory().appendingPathComponent("\(numberOfRecordings).m4a")
            transcribeAudio(url: sound)
//            seeAudioRecordings.reloadData()
            recordAudioLabel.setTitle("Speak", for: .normal)
        }
    }

    func didReceiveMessage(message: String) {
//        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        numberOfMessages += 1
        words.append(message)
//        print(words)
        prototypeChatMessages.reloadData()
//        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!")

    }
    
    func deleteAudioFiles()
    {
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//        print(documentsUrl)
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsUrl,
                                                                       includingPropertiesForKeys: nil,
                                                                       options: .skipsHiddenFiles)
//            print(fileURLs)
//            print("wat")
            for fileURL in fileURLs {
                if fileURL.pathExtension == "m4a" {
                    try FileManager.default.removeItem(at: fileURL)
                }
            }
        } catch  { print(error) }
    }
    
    func requestTranscribePermissions() {
        SFSpeechRecognizer.requestAuthorization { [unowned self] authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
//                    print("Good to go!")
                } else {
//                    print("Transcription permission was declined.")
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view
        recordingSession = AVAudioSession.sharedInstance()
        prototypeChatMessages.register(UITableViewCell.self, forCellReuseIdentifier: "proto")
        prototypeChatMessages.delegate = self
        prototypeChatMessages.dataSource = self
        
        if let count:Int = UserDefaults.standard.object(forKey: "num") as? Int
        {
            numberOfRecordings = count
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { (hasPermission) in if hasPermission
            {
//                print ("ACCEPTED")
            }
        }
        
        chats = SocketChatManager()
        chats.delegate = self
        requestTranscribePermissions()

    }
    
    // Find the audio storage location
    func getFileDirectory() -> URL
    {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let DDirectory = paths[0]
//        print(DDirectory)
        return DDirectory
    }
    
    func displayAnAlert(title:String, message:String)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "dismiss", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // Table View Setup
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfMessages
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let proto = tableView.dequeueReusableCell(withIdentifier: "proto", for: indexPath)
        proto.textLabel?.text = String(words[indexPath.row])
        return proto
    }
    
    func transcribeAudio(url: URL) {
        // create a new recognizer and point it at our audio
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: url)
//        print("yea")

        // start recognition!
        recognizer?.recognitionTask(with: request) { [unowned self] (result, error) in
            // abort if we didn't get any transcription back
            guard let result = result else {
//                print("There was an error: \(error!)")
                return
            }

            // if we got the final transcription back, print it
            if result.isFinal {
                // pull out the best transcription...
                let transcribing = result.bestTranscription.formattedString
//                print(transcribing)
                chats.send(message: transcribing)
                numberOfMessages += 1
                words.append(transcribing)
//                print(words)
                prototypeChatMessages.reloadData()
//                print(result.bestTranscription.formattedString)
                deleteAudioFiles()
            }
        }
    }
    
}

