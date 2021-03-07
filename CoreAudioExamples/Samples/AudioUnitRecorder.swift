//
//  AudioUnitRecorder.swift
//  CoreAudioExamples
//
//  Created by TokyoYoshida on 2021/03/07.
//

import AVFoundation
import AudioToolbox

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

