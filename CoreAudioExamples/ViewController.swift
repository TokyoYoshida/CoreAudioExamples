//
//  ViewController.swift
//  CoreAudioExamples
//
//  Created by TokyoYoshida on 2021/03/05.
//

import UIKit
import AVFoundation
import AudioToolbox

class ViewController: UIViewController {
    @IBOutlet weak var record: UIButton!
    @IBOutlet weak var play: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    
    var audioRecorder: AVAudioRecorder!

    var audioEngine: AVAudioEngine!
    var avAudioFile: AVAudioFile!
    var audioPlayerNode: AVAudioPlayerNode!
    
    // for Audio Unit
    var mPlayerGraph: AUGraph?
    var inputNode: AUNode = 0
    var mixerNode: AUNode = 0
    var inputNodeUnit: AudioUnit?
    var mixerNodeUnit: AudioUnit?
    // for Extended audio file service
    var audioFile: ExtAudioFileRef?
    
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

extension ViewController: AVAudioRecorderDelegate {
}

extension ViewController {
    func configureAudioUnit() throws {
        try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(0.01)
        try AVAudioSession.sharedInstance().setCategory(.multiRoute)
        try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
    
        var unitDesc = AudioComponentDescription()
        unitDesc.componentType = kAudioUnitType_Output
        unitDesc.componentSubType = kAudioUnitSubType_VoiceProcessingIO
        unitDesc.componentManufacturer = kAudioUnitManufacturer_Apple
        unitDesc.componentFlags = 0
        unitDesc.componentFlagsMask = 0
        
        if NewAUGraph(&mPlayerGraph) != noErr {
            fatalError("Cannot create audio graph.")
        }
        
        if AUGraphOpen(mPlayerGraph!) != noErr {
            fatalError("Cannot open audio graph.")
        }
        
        if AUGraphAddNode(mPlayerGraph!, &unitDesc, &inputNode) != noErr {
            fatalError("Cannot add node.")
        }

        var mixerDesc = AudioComponentDescription()
        mixerDesc.componentType = kAudioUnitType_Mixer
        mixerDesc.componentSubType = kAudioUnitSubType_MultiChannelMixer
        mixerDesc.componentManufacturer = kAudioUnitManufacturer_Apple
        mixerDesc.componentFlags = 0
        mixerDesc.componentFlagsMask = 0
        
        if AUGraphAddNode(mPlayerGraph!, &mixerDesc, &mixerNode) != noErr {
            fatalError("Cannot add node.")
        }
        
        if AUGraphNodeInfo(mPlayerGraph!, inputNode, nil, &inputNodeUnit) != noErr {
            fatalError("Wrong input node info.")
        }

        if AUGraphNodeInfo(mPlayerGraph!, mixerNode, nil, &mixerNodeUnit) != noErr {
            fatalError("Wrong mixer node info.")
        }
        
        if AUGraphConnectNodeInput(mPlayerGraph!, mixerNode, 0, inputNode, 0) != noErr {
            fatalError("Cannot connect node.")
        }

        var flag: UInt32 = 1
        if AudioUnitSetProperty(inputNodeUnit!, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &flag, UInt32(MemoryLayout<UInt32>.size)) != noErr {
            fatalError("Cannot set property.")
        }
           
        
    }

    func createAudioFile(url: URL, ofType type: AudioFileTypeID, forStreamDescription asbd: AudioStreamBasicDescription) {
        let formatFlags: AudioFormatFlags = (type == kAudioFileAIFFType) ? kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsBigEndian : kAudioFormatFlagIsSignedInteger
        var asbdOutput = AudioStreamBasicDescription(
                   mSampleRate: asbd.mSampleRate,
                   mFormatID: kAudioFormatLinearPCM,
                   mFormatFlags: formatFlags,
                   mBytesPerPacket: 4, mFramesPerPacket: 1, mBytesPerFrame: 4, mChannelsPerFrame: 2, mBitsPerChannel: 16, mReserved: 0)
        let result = ExtAudioFileCreateWithURL(url as CFURL, type, &asbdOutput, nil, AudioFileFlags.eraseFile.rawValue, &self.audioFile)
        if result != noErr || self.audioFile == nil {
            fatalError("Cannot create audio file.")
        }
    }
    
    func writeToAudioFile(_ buffers: UnsafeMutableAudioBufferListPointer, _ numFrames: UInt32) {
        guard let audioFile = self.audioFile else {
            return
        }
        ExtAudioFileWrite(audioFile, numFrames, buffers.unsafeMutablePointer)
    }
    
    func closeAudioFile() {
        if let audioFile = self.audioFile {
            ExtAudioFileDispose(audioFile)
        }
    }
}
