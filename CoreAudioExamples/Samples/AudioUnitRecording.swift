//
//  ViewController.swift
//  CoreAudioExamples
//
//  Created by TokyoYoshida on 2021/03/05.
//

import UIKit
import AVFoundation
import AudioToolbox

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
    var mAudioFormat = AudioStreamBasicDescription()
    var mixerFormat: AudioStreamBasicDescription?
    var mBuffers: AudioBufferList?
    // for Extended audio file service
    let audioWriter = AudioWriter()
    
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
    func configureAudioUnit() throws {
        mixerFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 2, interleaved: false)?.streamDescription.pointee
        
        mAudioFormat.mSampleRate = AVAudioSession.sharedInstance().preferredSampleRate
        mAudioFormat.mFormatID = kAudioFormatLinearPCM
        mAudioFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
        mAudioFormat.mFramesPerPacket = 1
        mAudioFormat.mBitsPerChannel = 16
        mAudioFormat.mChannelsPerFrame = 1
        mAudioFormat.mBytesPerFrame = mAudioFormat.mBitsPerChannel * mAudioFormat.mFramesPerPacket / 8
        mAudioFormat.mBytesPerPacket = mAudioFormat.mBytesPerFrame * mAudioFormat.mFramesPerPacket
        mAudioFormat.mReserved = 0
        
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
            fatalError("Cannot set output property.")
        }
        
        if AudioUnitSetProperty(inputNodeUnit!, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &flag, UInt32(MemoryLayout<UInt32>.size)) != noErr {
            fatalError("Cannot set input property.")
        }
           
        let numBuffers = 1
        
        let buffer = AudioBuffer(mNumberChannels: mAudioFormat.mChannelsPerFrame, mDataByteSize: 2048 * 2 * 10, mData: UnsafeMutableRawPointer.allocate(byteCount: Int(2048 * 2 * 10), alignment: 8))
        mBuffers = AudioBufferList(mNumberBuffers: UInt32(numBuffers), mBuffers: buffer)

        let renderCallBack: AURenderCallback = { inRefCon, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData in
            let instance = unsafeBitCast(inRefCon, to: AudioWriter.self)

            if ioActionFlags.pointee.rawValue & AudioUnitRenderActionFlags.unitRenderAction_PostRender.rawValue == AudioUnitRenderActionFlags.unitRenderAction_PostRender.rawValue {
                guard let abl = UnsafeMutableAudioBufferListPointer(ioData) else {
                    return noErr
                }
                instance.writeToAudioFile(abl, inNumberFrames)
            }
            return noErr
        }
        
        if AudioUnitAddRenderNotify(mixerNodeUnit!, renderCallBack, Unmanaged<AudioWriter>.passRetained(self.audioWriter).toOpaque()) != noErr {
            fatalError("Cannot add render notify.")
        }
    }
    
    func startAudioGraph() {
        if AUGraphInitialize(mPlayerGraph!) != noErr {
           fatalError("Cannot Audio Graph initialize.")
        }

        if AUGraphUpdate(mPlayerGraph!, nil) != noErr {
            fatalError("Cannot Audio Graph update.")
        }

        if AUGraphStart(mPlayerGraph!) != noErr {
            fatalError("Cannot start Audio Graph.")
        }
    }
    
    func stopAudioGraph() {
        if AUGraphStop(mPlayerGraph!) != noErr {
            fatalError("Cannot stop Audio Graph.")
        }
    }
    
    func startRecroding() throws {
        try configureAudioUnit()

//        var outputDesc: AudioStreamBasicDescription = AudioStreamBasicDescription()
//        outputDesc.mSampleRate = 44100
//        outputDesc.mFormatID = kAudioFormatLinearPCM
//        outputDesc.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
//        outputDesc.mReserved = 0
//        outputDesc.mChannelsPerFrame = 1
//        outputDesc.mBitsPerChannel = 16
//        outputDesc.mFramesPerPacket = 1
//        outputDesc.mBytesPerFrame = outputDesc.mChannelsPerFrame * outputDesc.mBitsPerChannel / 8
//        outputDesc.mBytesPerPacket = outputDesc.mBytesPerFrame * outputDesc.mFramesPerPacket
            
        
        let fileManager = FileManager.default
        let docs = try fileManager.url(for: .documentDirectory,
                                       in: .userDomainMask,
                                       appropriateFor: nil, create: false)
        let fileUrl = docs.appendingPathComponent("myFile.m4a")
        audioWriter.createAudioFile(url: fileUrl, ofType: kAudioFileM4AType, audioDesc: mixerFormat!)
        startAudioGraph()
    }
    
    func endRecording() {
        audioWriter.closeAudioFile()
        stopAudioGraph()
    }

}

class AudioUnitRecorder {
    class RefConData {
      var audioUnit: AudioUnit? = nil;
      var index: Int = 0;
    }

    var refData: RefConData = RefConData()

    func initializeAudioUnit() {
      var acd = AudioComponentDescription();
      acd.componentType         = kAudioUnitType_Output;
      acd.componentSubType      = kAudioUnitSubType_RemoteIO;
      acd.componentManufacturer = kAudioUnitManufacturer_Apple;
      acd.componentFlags        = 0;
      acd.componentFlagsMask    = 0;

      guard let ac = AudioComponentFindNext(nil, &acd) else { return  };
      AudioComponentInstanceNew( ac, &( refData.audioUnit ) );

//      initializeCallbacks();
//      initializeEnableIO();
//      initializeAudioFormat();
//      initializeAudioUnitSetting();

      AudioUnitInitialize( refData.audioUnit! );
    }
    
//    func initializeCallbacks() {
//      var inputCallback = AURenderCallbackStruct( inputProc: RecordingCallback, inputProcRefCon: Unmanaged<Looper.RefConData>.passRetained(refData).toOpaque() );
//      var outputCallback = AURenderCallbackStruct( inputProc: RenderCallback, inputProcRefCon: Unmanaged<Looper.RefConData>.passRetained(refData).toOpaque() );
//
//      AudioUnitSetProperty( refData.audioUnit!,
//                            kAudioOutputUnitProperty_SetInputCallback,
//                            kAudioUnitScope_Global,
//                            kInputBus,
//                            &inputCallback,
//                            UInt32(MemoryLayout<AURenderCallbackStruct>.size ) );
//
//      AudioUnitSetProperty( refData.audioUnit!,
//                            kAudioUnitProperty_SetRenderCallback,
//                            kAudioUnitScope_Global,
//                            kOutputBus,
//                            &outputCallback,
//                            UInt32(MemoryLayout<AURenderCallbackStruct>.size ) );
//    }
//
//    func initializeEnableIO() {
//      var flag: UInt32 = 1;
//      AudioUnitSetProperty( refData.audioUnit!,
//                            kAudioOutputUnitProperty_EnableIO,
//                            kAudioUnitScope_Input,
//                            kInputBus,
//                            &flag,
//                            UInt32( MemoryLayout<UInt32>.size ) );
//
//      AudioUnitSetProperty( refData.audioUnit!,
//                            kAudioOutputUnitProperty_EnableIO,
//                            kAudioUnitScope_Output,
//                            kOutputBus,
//                            &flag,
//                            UInt32( MemoryLayout<UInt32>.size ) );
//    }
//
//    func initializeAudioFormat() {
//      var audioFormat: AudioStreamBasicDescription = AudioStreamBasicDescription();
//      audioFormat.mSampleRate              = 44100.00;
//      audioFormat.mFormatID                = kAudioFormatLinearPCM;
//      audioFormat.mFormatFlags          = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
//      audioFormat.mFramesPerPacket    = 1;
//      audioFormat.mChannelsPerFrame    = 1;
//      audioFormat.mBitsPerChannel        = 16;
//      audioFormat.mBytesPerPacket        = 2;
//      audioFormat.mBytesPerFrame        = 2;
//
//      AudioUnitSetProperty( refData.audioUnit!,
//                            kAudioUnitProperty_StreamFormat,
//                            kAudioUnitScope_Output,
//                            kInputBus,
//                            &audioFormat,
//                            UInt32( MemoryLayout<AudioStreamBasicDescription>.size ) );
//
//      AudioUnitSetProperty( refData.audioUnit!,
//                            kAudioUnitProperty_StreamFormat,
//                            kAudioUnitScope_Input,
//                            kOutputBus,
//                            &audioFormat,
//                            UInt32( MemoryLayout<AudioStreamBasicDescription>.size ));
//    }
//
//    func initializeAudioUnitSetting() {
//      var flag = 0;
//      AudioUnitSetProperty( refData.audioUnit!,
//                            kAudioUnitProperty_ShouldAllocateBuffer,
//                            kAudioUnitScope_Output,
//                            kInputBus,
//                            &flag,
//                            UInt32( MemoryLayout<UInt32>.size ) );
//    }

    func start() {
        
    }
    
    func stop() {
        
    }
}

class AudioWriter {
    var audioFile: ExtAudioFileRef?

    func createAudioFile(url: URL, ofType type: AudioFileTypeID, audioDesc : AudioStreamBasicDescription) {
        var outputDesc = AudioStreamBasicDescription()

        if type == kAudioFileM4AType {
            outputDesc.mFormatID = kAudioFormatMPEG4AAC
            outputDesc.mFormatFlags = AudioFormatFlags(MPEG4ObjectID.AAC_LC.rawValue)
            outputDesc.mChannelsPerFrame = audioDesc.mChannelsPerFrame
            outputDesc.mSampleRate = audioDesc.mSampleRate
            outputDesc.mFramesPerPacket = 1024
            outputDesc.mBytesPerFrame = 0
            outputDesc.mBytesPerPacket = 0
            outputDesc.mBitsPerChannel = 0
            outputDesc.mReserved = 0
        } else if type == kAudioFileCAFType || type == kAudioFileWAVEType {
            outputDesc.mFormatID = kAudioFormatLinearPCM;
            outputDesc.mFormatFlags = kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
            outputDesc.mChannelsPerFrame = 2;
            outputDesc.mSampleRate = audioDesc.mSampleRate;
            outputDesc.mFramesPerPacket = 1;
            outputDesc.mBytesPerFrame = 4;
            outputDesc.mBytesPerPacket = 4;
            outputDesc.mBitsPerChannel = 16;
            outputDesc.mReserved = 0;
        }
        let result = ExtAudioFileCreateWithURL(url as CFURL, type, &outputDesc, nil, AudioFileFlags.eraseFile.rawValue, &self.audioFile)
        if result != noErr || self.audioFile == nil {
            fatalError("Cannot create audio file.")
        }
    }
    
    func writeToAudioFile(_ buffers: UnsafeMutableAudioBufferListPointer, _ numFrames: UInt32) {
        guard let audioFile = self.audioFile else {
            return
        }
        let result = ExtAudioFileWrite(audioFile, numFrames, buffers.unsafeMutablePointer)
        if result != noErr {
            fatalError("Error write file.\(result)")
        }
    }
    
    func closeAudioFile() {
        if let audioFile = self.audioFile {
            if ExtAudioFileDispose(audioFile) != noErr {
                fatalError("Cannot close file.")
            }
        }
    }
}
