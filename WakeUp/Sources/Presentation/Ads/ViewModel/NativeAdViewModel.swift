//
//  NativeAdViewModel.swift
//  WakeUp
//
//  Created by a on 12/16/25.
//

import Combine
import GoogleMobileAds

class NativeAdViewModel: NSObject, ObservableObject, NativeAdLoaderDelegate, NativeAdDelegate {
    @Published var nativeAd: NativeAd?
    
    private var adLoader: AdLoader!
    
    var isLoading: Bool {
        adLoader.isLoading
    }
    
    override init() {
        super.init()
        self.initAd()
    }
    
    /// 로더 초기화
    func initAd() {
        guard let adUnitID = Bundle.main.infoDictionary?["AdUnitID"] as? String else { return }
        
        adLoader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: nil,
            adTypes: [.native], options: nil)
        adLoader.delegate = self
    }
    
    /// 광고 표시
    func loadAd() {
        adLoader.load(Request())
    }
    
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        // Native ad data changes are published to its subscribers.
        self.nativeAd = nativeAd
        nativeAd.delegate = self
    }
    
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        print("\(adLoader) failed with error: \(error.localizedDescription)")
    }
}
