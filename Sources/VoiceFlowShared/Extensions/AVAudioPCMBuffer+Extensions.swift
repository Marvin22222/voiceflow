//
//  AVAudioPCMBuffer+Extensions.swift
//  VoiceFlowShared
//
//  Conveniences for working with AVAudioPCMBuffer in transcription pipelines.
//

import AVFoundation
import Foundation

// MARK: - AudioFormat

/// Standard PCM format expected by all transcription backends.
///
/// Most Whisper-family models expect 16 kHz, mono, Float32 PCM.
public enum StandardAudioFormat {
    
    /// Sample rate in Hz.
    public static let sampleRate: Double = 16_000
    
    /// Number of channels (mono).
    public static let channelCount: AVAudioChannelCount = 1
    
    /// Common format (Float32 is standard for ML).
    public static let commonFormat: AVAudioCommonFormat = .pcmFormatFloat32
    
    /// AVAudioFormat for the standard transcription input.
    public static var pcmFormat: AVAudioFormat {
        AVAudioFormat(
            commonFormat: commonFormat,
            sampleRate: sampleRate,
            channels: channelCount,
            interleaved: false
        )!
    }
}

// MARK: - AVAudioPCMBuffer Extensions

public extension AVAudioPCMBuffer {
    
    /// Creates an empty PCM buffer in the standard transcription format.
    static func makeStandardBuffer(capacity: AVAudioFrameCount = 4096) -> AVAudioPCMBuffer? {
        AVAudioPCMBuffer(pcmFormat: StandardAudioFormat.pcmFormat, frameCapacity: capacity)
    }
    
    /// Duration of the buffer in seconds.
    var duration: TimeInterval {
        guard frameLength > 0 else { return 0 }
        return Double(frameLength) / format.sampleRate
    }
    
    /// Number of samples (alias for `frameLength` for clarity).
    var sampleCount: AVAudioFrameCount { frameLength }
    
    /// Converts the buffer to mono Float32 if not already.
    func normalizedForTranscription() -> AVAudioPCMBuffer? {
        // If already in standard format, return self
        if format.sampleRate == StandardAudioFormat.sampleRate,
           format.channelCount == StandardAudioFormat.channelCount,
           format.commonFormat == StandardAudioFormat.commonFormat {
            return self
        }
        
        // Otherwise convert via AVAudioConverter
        let converter = AVAudioConverter(from: format, to: StandardAudioFormat.pcmFormat)
        guard let converter = converter else { return nil }
        
        let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: StandardAudioFormat.pcmFormat,
            frameCapacity: AVAudioFrameCount(Double(frameLength) * StandardAudioFormat.sampleRate / format.sampleRate)
        )
        guard let outputBuffer = outputBuffer else { return nil }
        
        var error: NSError?
        var consumed = false
        converter.convert(to: outputBuffer, error: &error) { _, status in
            if consumed {
                status.pointee = .noDataNow
                return nil
            }
            consumed = true
            status.pointee = .haveData
            return self
        }
        
        return error == nil ? outputBuffer : nil
    }
}
