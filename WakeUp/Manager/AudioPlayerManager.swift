//
//  AudioPlayerManager.swift
//  WakeUp
//
//  Created by a on 11/21/25.
//

import AVFoundation

final class AudioPlayerManager: NSObject {
    static let shared = AudioPlayerManager()
    
    private var audioPlayer: AVAudioPlayer?
    private let session = AVAudioSession.sharedInstance()
    
    private override init() {}
    
    /// 일정시간 이후 음악 재생
    func play(atTime: TimeInterval, volume: Float) {
        guard let url = Bundle.main.url(forResource: "sampleSound", withExtension: "caf") else {
            print("Not found audio file")
            return
        }
        
        do {
            // 세션 활성화
            try session.setCategory(.playback, options: .duckOthers)
            try session.setActive(true)
            
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = volume
            player.prepareToPlay()
            
            player.play(atTime: player.deviceCurrentTime + atTime)
            self.audioPlayer = player
        } catch {
            print("Error loading audio: \(error)")
        }
    }
    
    func stop() {
        do {
            audioPlayer?.stop()
            try session.setActive(false)
        } catch {
            
        }
    }
}
