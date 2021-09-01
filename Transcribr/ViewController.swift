//
//  ViewController.swift
//  Transcribr
//
//  Created by Rane Simons on 8/27/21.
//

import UIKit
import AVFoundation
import Speech

class ViewController: UIViewController, AVAudioRecorderDelegate, UITableViewDelegate, UITableViewDataSource {

    var recordingSession:AVAudioSession!
    var audioRecorder:AVAudioRecorder!
    var audioPlayer:AVAudioPlayer!
//    var player: AVAudioPlayer?
    var numberOfRecordings:Int = 0
    @IBOutlet weak var recordAudioLabel: UIButton!
    @IBOutlet weak var seeAudioRecordings: UITableView!
    
    func deleteAudioFiles()
    {
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//        print(documentsUrl)
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsUrl,
                                                                       includingPropertiesForKeys: nil,
                                                                       options: .skipsHiddenFiles)
            print(fileURLs)
            print("wat")
            for fileURL in fileURLs {
                if fileURL.pathExtension == "m4a" {
                    try FileManager.default.removeItem(at: fileURL)
                }
            }
        } catch  { print(error) }
    }
    
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
    
    func requestTranscribePermissions() {
        SFSpeechRecognizer.requestAuthorization { [unowned self] authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    print("Good to go!")
                } else {
                    print("Transcription permission was declined.")
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view
        recordingSession = AVAudioSession.sharedInstance()
        
        if let count:Int = UserDefaults.standard.object(forKey: "num") as? Int
        {
            numberOfRecordings = count
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { (hasPermission) in if hasPermission
            {
                print ("ACCEPTED")
            }
        }
        
        requestTranscribePermissions()
    }
    
    // Find the audio storage location
    func getFileDirectory() -> URL
    {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let DDirectory = paths[0]
        print(DDirectory)
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
        return numberOfRecordings
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let proto = tableView.dequeueReusableCell(withIdentifier: "proto", for: indexPath)
        proto.textLabel?.text = String(indexPath.row + 1)
        return proto
    }
    
    func transcribeAudio(url: URL) {
        // create a new recognizer and point it at our audio
        print("lol")
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: url)
        print("yea")

        // start recognition!
        recognizer?.recognitionTask(with: request) { [unowned self] (result, error) in
            // abort if we didn't get any transcription back
            guard let result = result else {
                print("There was an error: \(error!)")
                return
            }

            // if we got the final transcription back, print it
            if result.isFinal {
                // pull out the best transcription...
                print(result.bestTranscription.formattedString)
                deleteAudioFiles()
            }
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      let sound = getFileDirectory().appendingPathComponent("\(indexPath.row + 1).m4a")
//        let sound = getFileDirectory().appendingPathComponent("\(indexPath.row + 1).mp4a")
        
        do
        {
            audioPlayer = try AVAudioPlayer(contentsOf: sound)
            audioPlayer.play()
            transcribeAudio(url: sound)
        }
        catch
        {
            print(error.localizedDescription)
        }
    }
    
}

