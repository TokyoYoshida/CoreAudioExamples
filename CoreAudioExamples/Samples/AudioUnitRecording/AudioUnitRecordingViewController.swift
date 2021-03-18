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
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    
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
            } catch let error {
                fatalError(error.localizedDescription)
            }
        }
        
        super.viewDidLoad()

        initAudioRecorder()
    }
    
    @IBAction func tappedRecord(_ sender: Any) {
        if !isRecording {
            isRecording = true
            do {
                try startRecroding()
            } catch (let error) {
                print(error)
            }
            recordButton.setTitle("Stop", for: .normal)
        } else {
            isRecording = false
            endRecording()
            recordButton.setTitle("Record", for: .normal)
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
                audioPlayerNode.scheduleFile(avAudioFile, at: nil, completionCallbackType: .dataPlayedBack) {_ in
                    DispatchQueue.main.async {
                        self.playButton.setTitle("Play", for: .normal)
                    }
                }

                try audioEngine.start()
                audioPlayerNode.play()
                playButton.setTitle("Stop", for: .normal)
            } else {
                audioPlayerNode.stop()
                playButton.setTitle("Play", for: .normal)
            }
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
    
    func getAudioFileUrl() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docsDirect = paths[0]
        let audioUrl = docsDirect.appendingPathComponent("recording.wav")

        return audioUrl
    }
    
}

extension AudioUnitRecordingViewController: AVAudioRecorderDelegate {
}

extension AudioUnitRecordingViewController {
    func startRecroding() throws {
        let fileUrl = getAudioFileUrl()
        audioWriter.createAudioFile(url: fileUrl, ofType: kAudioFileWAVEType, audioDesc: auidoUnitRecorder.audioFormat)
        auidoUnitRecorder.start(audioWriter)
    }
    
    func endRecording() {
        auidoUnitRecorder.stop()
        audioWriter.closeAudioFile()
    }
}

