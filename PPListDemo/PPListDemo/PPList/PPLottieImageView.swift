//
//  PPLottieImageView.swift
//  PPListDemo
//
//  Created by Rex on 2022/11/17.
//

import SwiftUI
import Lottie
import SnapKit

/// Lottie动画视图转SwiftUI
///
/// **UIKit转成SwiftUI视图 换色过程必须在UIKit中实现

public struct PPLottieImageView: UIViewRepresentable {
    public typealias UIViewType = PPUIKitLottieImageView
    
    var image: String
    var image_dark: String? = nil
    var bundle: Bundle

    @Binding var play: Bool
    
    public func makeUIView(context: Context) -> PPUIKitLottieImageView {
        let lottie = PPUIKitLottieImageView(image: image, image_dark: image_dark, bundle: bundle)
        lottie.showAnimation()
        return lottie
    }
    
    public func updateUIView(_ uiView: PPUIKitLottieImageView, context: Context) {
        if play {
            uiView.showAnimation()
        } else {
            uiView.stopAnimation()
        }
    }
    
}

public class PPUIKitLottieImageView: UIView {

    private var animationView: LottieAnimationView!
    
    let image: String
    let image_dark: String
    let bundle: Bundle
    
    public init(image: String, image_dark: String? = nil, bundle: Bundle) {
        self.image = image
        self.image_dark = image_dark ?? image
        self.bundle = bundle
        super.init(frame: CGRect(origin: .zero, size: .zero))
        
        animationView = LottieAnimationView(name: image, bundle: bundle)
        animationView.loopMode = .loop
        addSubview(animationView)
        resetAnimation()
        
        animationView.snp.makeConstraints { make in
            make.size.equalToSuperview()
            make.center.equalToSuperview()
        }
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        resetAnimation()
    }
    
    func resetAnimation() {
        let animationImage: String = UITraitCollection.current.userInterfaceStyle == .dark ? image_dark : image
        animationView.animation = .named(animationImage, bundle: bundle)
        showAnimation()
    }
    
    public func showAnimation() {
        animationView.loopMode = .loop
        animationView.play()
    }
    
    public func stopAnimation() {
        animationView.stop()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
