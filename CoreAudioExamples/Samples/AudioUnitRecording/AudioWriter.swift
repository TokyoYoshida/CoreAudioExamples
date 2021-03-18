//
//  AudioWriter.swift
//  CoreAudioExamples
//
//  Created by TokyoYoshida on 2021/03/07.
//

import AVFoundation
import AudioToolbox

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
            outputDesc.mFormatID = kAudioFormatLinearPCM
            outputDesc.mFormatFlags = kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger
            outputDesc.mChannelsPerFrame = 1
            outputDesc.mSampleRate = audioDesc.mSampleRate
            outputDesc.mFramesPerPacket = 1
            outputDesc.mBytesPerFrame = 2
            outputDesc.mBytesPerPacket = 2
            outputDesc.mBitsPerChannel = 16
            outputDesc.mReserved = 0
        }
        let result = ExtAudioFileCreateWithURL(url as CFURL, type, &outputDesc, nil, AudioFileFlags.eraseFile.rawValue, &self.audioFile)
        if result != noErr || self.audioFile == nil {
            fatalError("Cannot create audio file.")
        }
    }
    
    func writeToAudioFile(_ buffers: UnsafePointer<AudioBufferList>, _ numFrames: UInt32) {
        guard let audioFile = self.audioFile else {
            return
        }
        let result = ExtAudioFileWrite(audioFile, numFrames, buffers)
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
    let dataSize = UInt32( 1 * inNumberFrames * UInt32( MemoryLayout<Int16>.size ) )
  let dataMem = malloc( Int( dataSize ) )
  let audioBuffer = AudioBuffer.init( mNumberChannels: 1, mDataByteSize: dataSize, mData: dataMem )
  var audioBufferList = AudioBufferList.init( mNumberBuffers: 1, mBuffers: audioBuffer )

  // AudioUnitRender呼び出し
  AudioUnitRender( refData.audioUnit!,
                   ioActionFlags,
                   inTimeStamp,
                   inBusNumber,
                   inNumberFrames,
                   &audioBufferList )

    
    refData.writer?.writeToAudioFile(&audioBufferList, inNumberFrames)

    free(dataMem)

  return noErr
}

func RenderCallback( inRefCon: UnsafeMutableRawPointer,
                     ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                     inTimeStamp: UnsafePointer<AudioTimeStamp>,
                     inBusNumber: UInt32,
                     inNumberFrames: UInt32,
                     ioData: UnsafeMutablePointer<AudioBufferList>?) -> (OSStatus)
{
    let refData = unsafeBitCast( inRefCon, to: AudioUnitRecorder.RefConData.self)
  // LoopSoundsから再生する範囲のAudioBufferを取得
//  let end = ( refData.currentLoop?.buffers.count )! % Int( refData.loopDatas.loopCount() )
//    let start = end - Int( inNumberFrames ) >= 0 ? end - Int( inNumberFrames ) : 0

//    let arr = refData.loopDatas.get( beginIndex: start, endIndex: end )

  // ioDataのバッファにコピー
    let buf = UnsafeMutableBufferPointer<Int16>( (ioData?.pointee.mBuffers)! )
//  for i in 0 ..< arr.count {
//    buf[ i ] = arr[ i ]
//  }

  return noErr
}
