//
//  ViewController.swift
//  CoreAudioExamples
//
//  Created by TokyoYoshida on 2021/03/05.
//

import UIKit
import AVFoundation
import AudioToolbox

let kOutputBus: UInt32 = 0;
let kInputBus: UInt32 = 1;

class AudioUnitRecordingViewController: UIViewController {
    @IBOutlet weak var record: UIButton!
    @IBOutlet weak var play: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    
    var audioRecorder: AVAudioRecorder!

    var audioEngine: AVAudioEngine!
    var avAudioFile: AVAudioFile!
    var audioPlayerNode: AVAudioPlayerNode!
    var isRecording: Bool = false
    
    // for Audio Unit
    var mPlayerGraph: AUGraph?
    var inputNode: AUNode = 0
    var mixerNode: AUNode = 0
    var inputNodeUnit: AudioUnit?
    var mixerNodeUnit: AudioUnit?
    var mBuffers: AudioBufferList?
    // for Extended audio file service
    let audioWriter = AudioWriter()
    let auidoUnitRecorder = AudioUnitRecorder()
    
    override func viewDidLoad() {
        func initAudioRecorder() {
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.playAndRecord, mode: .default)
                try session.setActive(true)

                auidoUnitRecorder.initializeAudioUnit()

                //                let settings = [
//                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
//                    AVSampleRateKey: 44100,
//                    AVNumberOfChannelsKey: 2,
//                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
//                ]

                    
//                audioRecorder = try AVAudioRecorder(url: getAudioFileUrl(), settings: settings)
//                audioRecorder.delegate = self
            } catch let error {
                fatalError(error.localizedDescription)
            }
        }
//        func setTimer() {
//            Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true, block: { (timer) in
//                       self.updateTime()
//                   }
//            )
//        }
        
        super.viewDidLoad()

        initAudioRecorder()
//        setTimer()
    }
    
//    func updateTime() {
//        DispatchQueue.main.async {
//            self.timeLabel.text = String(self.audioRecorder.currentTime)
//        }
//    }
    
    @IBAction func tappedRecord(_ sender: Any) {
        if !isRecording {
            isRecording = true
//            audioRecorder.record()
            do {
                try startRecroding()
            } catch (let error) {
                print(error)
            }
            record.setTitle("Stop", for: .normal)
        } else {
            isRecording = false
//            audioRecorder.stop()
            endRecording()
            record.setTitle("Record", for: .normal)
        }
    }
    
    @IBAction func tappedPlay(_ sender: Any) {
        func initPlayer() {
            do {
                audioEngine = AVAudioEngine()
                avAudioFile = try AVAudioFile(forReading: getAudioFileUrl())
                audioPlayerNode = AVAudioPlayerNode()
                
                audioEngine.attach(audioPlayerNode)
                audioEngine.connect(audioPlayerNode, to: audioEngine.outputNode, format: avAudioFile.processingFormat)
            } catch let error {
                fatalError(error.localizedDescription)
            }
        }
        initPlayer()
        do {
            if !audioPlayerNode.isPlaying {
                audioPlayerNode.stop()
                audioPlayerNode.scheduleFile(avAudioFile, at: nil)

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

extension AudioUnitRecordingViewController: AVAudioRecorderDelegate {
}

extension AudioUnitRecordingViewController {

    func startRecroding() throws {
        let fileManager = FileManager.default
        let docs = try fileManager.url(for: .documentDirectory,
                                       in: .userDomainMask,
                                       appropriateFor: nil, create: false)
        let fileUrl = docs.appendingPathComponent("myFile.m4a")
        audioWriter.createAudioFile(url: fileUrl, ofType: kAudioFileM4AType, audioDesc: auidoUnitRecorder.audioFormat)
        auidoUnitRecorder.start(audioWriter)
    }
    
    func endRecording() {
        audioWriter.closeAudioFile()
        auidoUnitRecorder.stop()
    }

}

