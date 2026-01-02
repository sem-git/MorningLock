//
//  NativeAdMobView.swift
//  WakeUp
//
//  Created by a on 12/15/25.
//

import SwiftUI
import Combine
import GoogleMobileAds

struct NativeAdMobView: UIViewRepresentable {
    typealias UIViewType = NativeAdView
    
    @ObservedObject var nativeViewModel: NativeAdViewModel
    
    func makeUIView(context: Context) -> NativeAdView {
        Bundle.main.loadNibNamed(
            "NativeAdView",
            owner: nil,
            options: nil)?.first as! NativeAdView        
    }
    
    func updateUIView(_ nativeAdView: NativeAdView, context: Context) {
        guard let nativeAd = nativeViewModel.nativeAd else {
            nativeAdView.isHidden = true
            return
        }
        nativeAdView.isHidden = false
        
        // Each UI property is configurable using your native ad.
        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
        
        nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent
        
        (nativeAdView.bodyView as? UILabel)?.text = (nativeAd.body ?? "")
        
        (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        
        //        (nativeAdView.starRatingView as? UIImageView)?.image = imageOfStars(from: nativeAd.starRating)
        
        (nativeAdView.storeView as? UILabel)?.text = nativeAd.store
        
        (nativeAdView.priceView as? UILabel)?.text = nativeAd.price
        
        (nativeAdView.advertiserView as? UILabel)?.text = nativeAd.advertiser
        
        (nativeAdView.callToActionView as? UIButton)?.setTitle("설치", for: .normal)
        
        // For the SDK to process touch events properly, user interaction should be disabled.
        nativeAdView.callToActionView?.isUserInteractionEnabled = true
        
        // Associate the native ad view with the native ad object. This is required to make the ad
        // clickable.
        // Note: this should always be done after populating the ad views.
        nativeAdView.nativeAd = nativeAd
    }
}

#Preview {
    NativeAdMobView(nativeViewModel: NativeAdViewModel(isDisabled: false))
}
