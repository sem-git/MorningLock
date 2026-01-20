//
//  AudioPlayerManager.swift
//  WakeUp
//
//  Created by a on 11/21/25.
//

import AVFoundation
import MediaPlayer
import Combine

final class AudioPlayerManager: NSObject {
    static let shared = AudioPlayerManager()
    
    private var audioPlayer: AVAudioPlayer?
    private var volumeObservation: NSKeyValueObservation?
    private var canellable: AnyCancellable?
    
    private let defaultVolume: Float = 1.0
    private let session = AVAudioSession.sharedInstance()
    
    private lazy var systemVolumeSlider: UISlider? = {
        let volumeView = MPVolumeView(frame: .zero)
        return volumeView.subviews.compactMap { $0 as? UISlider }.first
    }()
    
    private var systemVolume: Float {
        get { systemVolumeSlider?.value ?? defaultVolume }
        set { systemVolumeSlider?.value = newValue }
    }
    
    private override init() {
        super.init()
    }
    
    private func setupVolumeObservation() {
        volumeObservation = session.observe(\.outputVolume, options: [.new]) { [weak self] _, _ in
            guard let self = self else { return }
            systemVolume = defaultVolume
        }
    }
    
    /// 일정 시간 이후 음악 재생
    func play(atTime: TimeInterval, volume: Float) {
        guard let url = Bundle.main.url(forResource: "perfect-beauty", withExtension: "mp3") else {
            print("Not found audio file")
            return
        }
        
        do {
            // 세션 활성화
            try session.setCategory(.playback, options: .duckOthers)
            try session.setActive(true)
            
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = 1
            player.volume = defaultVolume
            player.prepareToPlay()
            player.play(atTime: player.deviceCurrentTime + atTime)
            self.audioPlayer = player
            
        } catch {
            print("Error loading audio: \(error)")
        }
    }
    
    /// 오디오세션 종료
    func stop() {
        do {
            audioPlayer?.stop()
            volumeObservation?.invalidate()
            try session.setActive(false)
        } catch {
            
        }
    }
}
