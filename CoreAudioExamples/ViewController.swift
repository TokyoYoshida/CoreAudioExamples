//
//  ViewController.swift
//  CoreAudioExamples
//
//  Created by TokyoYoshida on 2021/03/05.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var record: UIButton!
    @IBOutlet weak var play: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    
    var audioRecorder: AVAudioRecorder!

    var audioEngine: AVAudioEngine!
    var audioFile: AVAudioFile!
    var audioPlayerNode: AVAudioPlayerNode!
    
    override func viewDidLoad() {
        func initAudioRecorder() {
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.playAndRecord, mode: .default)
                try session.setActive(true)

                let settings = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 2,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]

                audioRecorder = try AVAudioRecorder(url: getAudioFileUrl(), settings: settings)
                audioRecorder.delegate = self
            } catch let error {
                fatalError(error.localizedDescription)
            }
        }
        func setTimer() {
            Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true, block: { (timer) in
                       self.updateTime()
                   }
            )
        }
        
        super.viewDidLoad()

        initAudioRecorder()
        setTimer()
    }
    
    func updateTime() {
        DispatchQueue.main.async {
            self.timeLabel.text = String(self.audioRecorder.currentTime)
        }
    }
    
    @IBAction func tappedRecord(_ sender: Any) {
        if !audioRecorder.isRecording {
            audioRecorder.record()
            record.setTitle("Stop", for: .normal)
        } else {
            audioRecorder.stop()
            record.setTitle("Record", for: .normal)
        }
    }
    
    @IBAction func tappedPlay(_ sender: Any) {
        func initPlayer() {
            do {
                audioEngine = AVAudioEngine()
                audioFile = try AVAudioFile(forReading: getAudioFileUrl())
                audioPlayerNode = AVAudioPlayerNode()
                
                audioEngine.attach(audioPlayerNode)
                audioEngine.connect(audioPlayerNode, to: audioEngine.outputNode, format: audioFile.processingFormat)
            } catch let error {
                fatalError(error.localizedDescription)
            }
        }
        initPlayer()
        do {
            if !audioPlayerNode.isPlaying {
                audioPlayerNode.stop()
                audioPlayerNode.scheduleFile(audioFile, at: nil)

                try audioEngine.start()
                audioPlayerNode.play()
                play.setTitle("Stop", for: .normal)
            } else {
                audioPlayerNode.stop()
                play.setTitle("Play", for: .normal)
            }
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
    
    func getAudioFileUrl() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docsDirect = paths[0]
        let audioUrl = docsDirect.appendingPathComponent("recording.m4a")

        return audioUrl
    }
}

extension ViewController: AVAudioRecorderDelegate {
}
