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
    
    override init() {
        super.init()
        self.refreshAd()
    }

  func refreshAd() {
    adLoader = AdLoader(
      adUnitID: "ca-app-pub-3940256099942544/3986624511",
      rootViewController: nil,
      adTypes: [.native], options: nil)
    adLoader.delegate = self
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
