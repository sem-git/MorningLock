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
    
    private var player: AVPlayer?
    private var volumeObservation: NSKeyValueObservation?
    private var timeObserverToken: Any?
    
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
    
    /// 볼륨 강제 조절
    private func startVolumeMonitoring() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            systemVolume = defaultVolume
            
            volumeObservation = session.observe(\.outputVolume) { [weak self] session, _ in
                self?.systemVolume = self?.defaultVolume ?? 1.0
            }
        }
    }
    
    
    
    /// 일정 시간 이후 음악 재생
    func play(atTime: TimeInterval, volume: Float) {
        do {
            // 세션 활성화
            try session.setCategory(.playback, options: .duckOthers)
            try session.setActive(true)
            
            guard let url = Bundle.main.url(forResource: "perfect-beauty", withExtension: "mp3") else {
                print("Not found audio file")
                return
            }
            
            let trackComposition = AVMutableComposition()
            let sourceAsset = AVAsset(url: url)
            
            guard let audioTrack = trackComposition.addMutableTrack(
                   withMediaType: .audio,
                   preferredTrackID: kCMPersistentTrackID_Invalid
               ),
            let sourceTrack = sourceAsset.tracks(withMediaType: .audio).first else { return }
            let duration = sourceAsset.duration
            
            var time = CMTime.zero
            
            for _ in Array(repeating: 1, count: 60 * 24 * 7) {
                try? audioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: sourceTrack, at: time)
                time = time + duration
            }
            
            // 플레이어 초기화
            player = AVPlayer(playerItem: AVPlayerItem(asset: trackComposition))
            player?.volume = 0.0
            player?.play()
            
            // 힘수를 호출할 시점을 나타내는 배열
            let triggerTime = CMTime(seconds: atTime, preferredTimescale: 600)
            
            // 알람시간이 경과할경우 해당 함수가 호출된다
            timeObserverToken = player?.addBoundaryTimeObserver(forTimes: [NSValue(time: triggerTime)], queue: .global(qos: .background)) { [weak self] in
                guard let self else { return }
                systemVolume = defaultVolume
                player?.volume = 1.0
                startVolumeMonitoring()
            }
            
        } catch {
            print("Error loading audio: \(error)")
        }
    }
    
    /// 오디오세션 종료
    func stop() {
        do {
            // 플레이어 일시중지
            player?.pause()
            // 옵저빙 취소
            if let token = timeObserverToken {
                player?.removeTimeObserver(token)
                timeObserverToken = nil
            }
            volumeObservation?.invalidate()
            try session.setActive(false)
        } catch {
            
        }
    }
}
