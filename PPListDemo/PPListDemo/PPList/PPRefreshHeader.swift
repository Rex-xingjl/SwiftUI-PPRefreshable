//
//  RefreshHeader.swift
//  PPListDemo
//
//  Created by Rex on 2022/11/17.
//

import SwiftUI
import Lottie
import MJRefresh

/// 列表顶部下拉刷新

public struct PPRefreshHeader: View {
    @Binding var play: Bool

    public init(play: Binding<Bool>) {
        _play = play
    }

    public var body: some View {
        VStack {
            PPLottieImageView(image: "header_loading",
                              image_dark: "header_loading_dark",
                              bundle: .main,
                              play: $play).frame(width: 44, height: 44, alignment: .center)
            Text(verbatim: "Good Luck")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(height: 13, alignment: .center)
        }
    }
}

/// 列表顶部下拉刷新 老版本

public class PPRefreshHeader_Old: MJRefreshHeader {

    private var loadingAnimationView: LottieAnimationView!
    private var loadingTextLabel: UILabel!

    public enum LoadingFinishType {
        case success
        case failWithNetwork
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        resetLoadingAnimation()
    }
    
    func resetLoadingAnimation() {
        let animationImage: String = UITraitCollection.current.userInterfaceStyle == .dark ? "header_loading_dark" : "header_loading"
        loadingAnimationView.animation = .named(animationImage, bundle: .main)
        showLoadingAnimation()
    }

    public override func prepare() {
        super.prepare()
        mj_h = 89

        let loadingAnimationViewWH: CGFloat = 44
        loadingAnimationView = LottieAnimationView(name: "header_loading", bundle: .main)
        loadingAnimationView.loopMode = .loop
        loadingAnimationView.frame.size = CGSize(width: loadingAnimationViewWH, height: loadingAnimationViewWH)
        addSubview(loadingAnimationView)
        resetLoadingAnimation()
        
        loadingTextLabel = UILabel()
        loadingTextLabel.text =  "Good Luck！"
        loadingTextLabel.font = .systemFont(ofSize: 11, weight: .regular)
        loadingTextLabel.textColor = .secondaryLabel
        loadingTextLabel.frame.size = CGSize(width: 300, height: 13)
        loadingTextLabel.textAlignment = .center
        addSubview(loadingTextLabel)
    }

    public override func placeSubviews() {
        super.placeSubviews()

        var loadingFrame = loadingAnimationView.frame
        loadingFrame.origin = CGPoint(x: (mj_w - loadingAnimationView.frame.width) / 2, y: 12)
        loadingAnimationView.frame = loadingFrame
        
        var textFrame = loadingTextLabel.frame
        textFrame.origin = CGPoint(x: (mj_w - loadingTextLabel.frame.width) / 2, y: loadingAnimationView.frame.origin.y + loadingAnimationView.frame.height + 8)
        loadingTextLabel.frame = textFrame
    }

    public override var state: MJRefreshState {
        didSet {
            switch state {
            case .idle: hideLoadingAnimation()
            case .pulling: showLoadingAnimation()
            case .refreshing: showLoadingAnimation()
            default: break
            }
        }
    }

    public var isInEndingDelay = false

    public override func endRefreshing() {
        if isInEndingDelay {
            return
        }
        super.endRefreshing()
    }

    public func endRefreshing(contentType: PPRefreshHeader_Old.LoadingFinishType, packUpDealy: TimeInterval = 2, completionBlock: @escaping () -> Void) {
        if isInEndingDelay || state == .idle {
            return
        }
        isInEndingDelay = true
        DispatchQueue.main.async {
        switch contentType {
        case .success:
            self.hideLoadingAnimation()
        case .failWithNetwork:
            self.hideLoadingAnimation()
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + packUpDealy) {
            self.isInEndingDelay = false
            super.endRefreshing(completionBlock: {
                self.hideLoadingAnimation()
                completionBlock()
            })
        }
        }
    }

    public func showLoadingAnimation() {
        loadingAnimationView.loopMode = .loop
        loadingAnimationView.play()
    }
    public func hideLoadingAnimation() {
        if loadingAnimationView.isAnimationPlaying {
            loadingAnimationView.pause()
        }
    }
}

