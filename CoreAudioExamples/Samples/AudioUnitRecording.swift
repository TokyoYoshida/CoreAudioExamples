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
    var mAudioFormat = AudioStreamBasicDescription()
    var mixerFormat: AudioStreamBasicDescription?
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
        audioWriter.createAudioFile(url: fileUrl, ofType: kAudioFileM4AType, audioDesc: mixerFormat!)
        auidoUnitRecorder.start()
    }
    
    func endRecording() {
        audioWriter.closeAudioFile()
        auidoUnitRecorder.stop()
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

      initializeCallbacks();
      initializeEnableIO();
      initializeAudioFormat();
      initializeAudioUnitSetting();

      AudioUnitInitialize( refData.audioUnit! );
    }
    
    func initializeCallbacks() {
      var inputCallback = AURenderCallbackStruct( inputProc: RecordingCallback, inputProcRefCon: Unmanaged<AudioUnitRecorder.RefConData>.passRetained(refData).toOpaque() );
      var outputCallback = AURenderCallbackStruct( inputProc: RenderCallback, inputProcRefCon: Unmanaged<AudioUnitRecorder.RefConData>.passRetained(refData).toOpaque() );

      AudioUnitSetProperty( refData.audioUnit!,
                            kAudioOutputUnitProperty_SetInputCallback,
                            kAudioUnitScope_Global,
                            kInputBus,
                            &inputCallback,
                            UInt32(MemoryLayout<AURenderCallbackStruct>.size ) );

      AudioUnitSetProperty( refData.audioUnit!,
                            kAudioUnitProperty_SetRenderCallback,
                            kAudioUnitScope_Global,
                            kOutputBus,
                            &outputCallback,
                            UInt32(MemoryLayout<AURenderCallbackStruct>.size ) );
    }

    func initializeEnableIO() {
      var flag: UInt32 = 1;
      AudioUnitSetProperty( refData.audioUnit!,
                            kAudioOutputUnitProperty_EnableIO,
                            kAudioUnitScope_Input,
                            kInputBus,
                            &flag,
                            UInt32( MemoryLayout<UInt32>.size ) );

      AudioUnitSetProperty( refData.audioUnit!,
                            kAudioOutputUnitProperty_EnableIO,
                            kAudioUnitScope_Output,
                            kOutputBus,
                            &flag,
                            UInt32( MemoryLayout<UInt32>.size ) );
    }

    func initializeAudioFormat() {
      var audioFormat: AudioStreamBasicDescription = AudioStreamBasicDescription();
      audioFormat.mSampleRate              = 44100.00;
      audioFormat.mFormatID                = kAudioFormatLinearPCM;
      audioFormat.mFormatFlags          = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
      audioFormat.mFramesPerPacket    = 1;
      audioFormat.mChannelsPerFrame    = 1;
      audioFormat.mBitsPerChannel        = 16;
      audioFormat.mBytesPerPacket        = 2;
      audioFormat.mBytesPerFrame        = 2;

      AudioUnitSetProperty( refData.audioUnit!,
                            kAudioUnitProperty_StreamFormat,
                            kAudioUnitScope_Output,
                            kInputBus,
                            &audioFormat,
                            UInt32( MemoryLayout<AudioStreamBasicDescription>.size ) );

      AudioUnitSetProperty( refData.audioUnit!,
                            kAudioUnitProperty_StreamFormat,
                            kAudioUnitScope_Input,
                            kOutputBus,
                            &audioFormat,
                            UInt32( MemoryLayout<AudioStreamBasicDescription>.size ));
    }

    func initializeAudioUnitSetting() {
      var flag = 0;
      AudioUnitSetProperty( refData.audioUnit!,
                            kAudioUnitProperty_ShouldAllocateBuffer,
                            kAudioUnitScope_Output,
                            kInputBus,
                            &flag,
                            UInt32( MemoryLayout<UInt32>.size ) );
    }

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

func RecordingCallback( inRefCon: UnsafeMutableRawPointer,
                     ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                     inTimeStamp: UnsafePointer<AudioTimeStamp>,
                     inBusNumber: UInt32,
                     inNumberFrames: UInt32,
                     ioData: UnsafeMutablePointer<AudioBufferList>?) -> (OSStatus)
{
    let refData = unsafeBitCast( inRefCon, to: AudioUnitRecorder.RefConData.self)
  // バッファ確保
  // バッファサイズ計算。Channel * Frame * sizeof( Int16 )
    let dataSize = UInt32( 1 * inNumberFrames * UInt32( MemoryLayout<Int16>.size ) );
  let dataMem = malloc( Int( dataSize ) );
  let audioBuffer = AudioBuffer.init( mNumberChannels: 1, mDataByteSize: dataSize, mData: dataMem );
  var audioBufferList = AudioBufferList.init( mNumberBuffers: 1, mBuffers: audioBuffer );

  // AudioUnitRender呼び出し
  AudioUnitRender( refData.audioUnit!,
                   ioActionFlags,
                   inTimeStamp,
                   inBusNumber,
                   inNumberFrames,
                   &audioBufferList );

  // もらってきたバッファをLoopSoundsにadd
  let ubpBuf = UnsafeBufferPointer<Int16>( audioBufferList.mBuffers );
//    refData.currentLoop!.add( buffer: Array( ubpBuf ) );
  free(dataMem)

  return noErr;
}

/**
 * 音声出力コールバックです
 */

func RenderCallback( inRefCon: UnsafeMutableRawPointer,
                     ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                     inTimeStamp: UnsafePointer<AudioTimeStamp>,
                     inBusNumber: UInt32,
                     inNumberFrames: UInt32,
                     ioData: UnsafeMutablePointer<AudioBufferList>?) -> (OSStatus)
{
    let refData = unsafeBitCast( inRefCon, to: AudioUnitRecorder.RefConData.self)
  // LoopSoundsから再生する範囲のAudioBufferを取得
//  let end = ( refData.currentLoop?.buffers.count )! % Int( refData.loopDatas.loopCount() );
//    let start = end - Int( inNumberFrames ) >= 0 ? end - Int( inNumberFrames ) : 0

//    let arr = refData.loopDatas.get( beginIndex: start, endIndex: end );

  // ioDataのバッファにコピー
    let buf = UnsafeMutableBufferPointer<Int16>( (ioData?.pointee.mBuffers)! );
//  for i in 0 ..< arr.count {
//    buf[ i ] = arr[ i ];
//  }

  return noErr;
}
