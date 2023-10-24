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

fileprivate let PPOffsetSpaceName: String = "OffsetSpaceName"
public struct PPOffsetPreferenceKey: PreferenceKey {
    public static var defaultValue: CGPoint = .zero
    public static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { }
}

public let defaultRefreshThreshold: CGFloat = 89

public enum RefreshState {
    case waiting, primed, loading, finishing
    
    var showRefreshView: Bool {
        switch self {
        case .loading, .finishing: return true
        default: return false
        }
    }
    
    var animating: Bool {
        switch self {
        case .primed, .loading: return true
        default: return false
        }
    }
}

public typealias PPRefreshProgressBuilder<Progress: View> = (RefreshState) -> Progress

public struct PPRefreshableScrollView<Progress, Content>: View where Progress: View, Content: View {
    let showsIndicators: Bool
    let loadingViewBackgroundColor: Color
    let threshold: CGFloat
    let onRefresh: OnRefresh
    let progress: PPRefreshProgressBuilder<Progress>
    let content: () -> Content
    @Binding private var isRefreshing: Bool
    @State private var offset: CGFloat = 0
    @State private var state: RefreshState = .waiting // the current state

    public init(_ isRefreshing: Binding<Bool>,
                showsIndicators: Bool = true,
                loadingViewBackgroundColor: Color = .clear,
                threshold: CGFloat = defaultRefreshThreshold,
                onRefresh: @escaping OnRefresh,
                @ViewBuilder progress: @escaping PPRefreshProgressBuilder<Progress>,
                @ViewBuilder content: @escaping () -> Content) {
        _isRefreshing = isRefreshing
        self.showsIndicators = showsIndicators
        self.loadingViewBackgroundColor = loadingViewBackgroundColor
        self.threshold = threshold
        self.onRefresh = onRefresh
        self.progress = progress
        self.content = content
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: showsIndicators) {
            /// ScrollView无法修改spacing content与GeometryReader存在默认间距8 所以这里增加VStack
            VStack(spacing: 0) {
                GeometryReader { proxy in
                    contentBody.preference(
                        key: PPOffsetPreferenceKey.self,
                        value: proxy.frame(in: .named(PPOffsetSpaceName)).origin
                    )
                }
            }
        }
        .ignoresSafeArea(.keyboard) /// 忽视其他界面弹起键盘导致的底部异常高度问题
        .coordinateSpace(name: PPOffsetSpaceName)
        .onPreferenceChange(PPOffsetPreferenceKey.self) { offsetChange($0) }
        .onChange(of: isRefreshing) { if $0 { refreshStart() } }
    }

    public var contentBody: some View {
        VStack(spacing: 0) {
            ZStack {
                Rectangle()
                    .foregroundColor(loadingViewBackgroundColor)
                    .frame(height: threshold)
                progress(state)
            }
            content()
        }
        .padding(.top, state.showRefreshView ? -max(0, offset) : -threshold)
    }
    
    private func offsetChange(_ off: CGPoint) {
        /// 这里需要主线程回传 规避一些线程异常情况
        Task { @MainActor in
            /// 在某些机型上 将Y直接设置给offset会造成SwiftUI循环刷新 这里尝试了很多次 确定为现在的逻辑
            let Y = off.y
            if Y > threshold && state == .waiting {
                offset = Y
                state = .primed
            } else if Y <= threshold && state == .primed {
                offset = Y
                isRefreshing = true
            } else {
                /// iOS14会出现异常: Bound preference PPOffsetPreferenceKey tried to update multiple times per frame.
                if #available(iOS 15, *) { offset = Y }
            }
        }
    }
    
    private func refreshStart() {
        Task { @MainActor in
            withAnimation { state = .loading }
            onRefresh {
                refreshEnd { isRefreshing = false }
            }
        }
    }
    
    /// 结束动画
    private func refreshEnd(_ back: (() -> Void)?) {
        Task { @MainActor in
            /// Delay of 0.35 seconds (1 second = 1_000_000_000 nanoseconds)
            try? await Task.sleep(nanoseconds: 350_000_000)
            self.state = .finishing
            /// Delay of 1 seconds
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            withAnimation { self.state = .waiting }
            
            back?()
        }
    }
}
