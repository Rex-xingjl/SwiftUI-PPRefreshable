//
//  RefreshableScrollView.swift
//  PPListDemo
//
//  Created by Rex on 2023/2/21.
//

import Foundation
import SwiftUI

public typealias RefreshCompleted = () -> Void

public typealias OnRefresh = (@escaping RefreshCompleted) -> Void

public let defaultRefreshThreshold: CGFloat = 89

public enum RefreshState {
    case waiting, primed, loading, finishing
}

public typealias PPRefreshProgressBuilder<Progress: View> = (RefreshState) -> Progress

public struct PPRefreshableScrollView<Progress, Content>: View where Progress: View, Content: View {
    let showsIndicators: Bool
    let loadingViewBackgroundColor: Color
    let threshold: CGFloat
    let onRefresh: OnRefresh
    let progress: PPRefreshProgressBuilder<Progress>
    let content: () -> Content
    @State private var offset: CGFloat = 0
    @State private var state = RefreshState.waiting // the current state

    public init(showsIndicators: Bool = true,
                loadingViewBackgroundColor: Color = .clear,
                threshold: CGFloat = defaultRefreshThreshold,
                onRefresh: @escaping OnRefresh,
                @ViewBuilder progress: @escaping PPRefreshProgressBuilder<Progress>,
                @ViewBuilder content: @escaping () -> Content) {
        self.showsIndicators = showsIndicators
        self.loadingViewBackgroundColor = loadingViewBackgroundColor
        self.threshold = threshold
        self.onRefresh = onRefresh
        self.progress = progress
        self.content = content
    }

    public var body: some View {
        PPOffsetableScrollView(axes: .vertical, showsIndicator: showsIndicators) { proxy in
            /// 在某些机型上 将Y直接设置给offset会造成SwiftUI循环刷新 这里尝试了很多次 确定为现在的逻辑
            let Y = proxy.y
            if state == .loading || state == .finishing { // If we're already loading, ignore everything
                offset = Y
            } else {
                if Y > threshold && state == .waiting {
                    offset = Y
                    state = .primed
                } else if Y <= threshold && state == .primed {
                    offset = Y
                    state = .loading
                    onRefresh {
                        Task {
                            // Delay of 0.35 seconds (1 second = 1_000_000_000 nanoseconds)
                            try? await Task.sleep(nanoseconds: 350_000_000)
                            await MainActor.run { self.state = .finishing }
                            // Delay of 1 seconds
                            try? await Task.sleep(nanoseconds: 1_000_000_000)
                            await MainActor.run { withAnimation { self.state = .waiting } }
                        }
                    }
                } else {
                    // iOS14会出现异常: Bound preference PPOffsetPreferenceKey tried to update multiple times per frame.
                    if #available(iOS 15, *) {
                        offset = Y
                    }
                }
            }
        } content: {
            ZStack(alignment: .top) {
                ZStack {
                    Rectangle()
                        .foregroundColor(loadingViewBackgroundColor)
                        .frame(height: threshold)
                    progress(state)
                }.offset(y: (state == .loading || state == .finishing) ? -max(0, offset) : -threshold)
                    
                content()
                    .alignmentGuide(.top) { _ in
                        (state == .loading || state == .finishing) ? -threshold + max(0, offset) : 0
                    }
            }
        }
    }
}
