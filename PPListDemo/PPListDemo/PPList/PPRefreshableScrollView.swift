//
//  RefreshableScrollView.swift
//  PPListDemo
//
//  Created by Rex on 2023/2/21.
//

import Foundation
import SwiftUI

public typealias PPRefreshProgressBuilder<Progress: View> = (RefreshState) -> Progress

public enum RefreshState {
    case waiting, primed, loading, finishing
    
    /// 保持住刷新状态视图的显示
    var holdRefreshView: Bool {
        switch self {
        case .loading, .finishing: return true
        default: return false
        }
    }
    
    /// 动画状态
    var animating: Bool {
        switch self {
        case .primed, .loading: return true
        default: return false
        }
    }
}

fileprivate let PPOffsetSpaceName: String = "OffsetSpaceName"
public struct PPOffsetPreferenceKey: PreferenceKey {
    public static var defaultValue: CGPoint = .zero
    public static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { }
}

/// 临界值
public let defaultRefreshThreshold: CGFloat = 89

public struct PPRefreshableScrollView<Progress, Content>: View where Progress: View, Content: View {
    let showsIndicators: Bool
    let loadingViewBackgroundColor: Color
    let threshold: CGFloat
    let progress: PPRefreshProgressBuilder<Progress>
    let content: () -> Content
    
    let refreshAction: @Sendable () async -> Void
    
    @Binding private var isRefreshing: Bool
    @State private var isRefreshEnding: Bool = false
    @State private var offset: CGFloat = 0
    @State private var state: RefreshState = .waiting // the current state
    
    public init(_ isRefreshing: Binding<Bool>,
                showsIndicators: Bool = true,
                loadingViewBackgroundColor: Color = .clear,
                threshold: CGFloat = defaultRefreshThreshold,
                refreshAction: @escaping @Sendable () async -> Void,
                @ViewBuilder progress: @escaping PPRefreshProgressBuilder<Progress>,
                @ViewBuilder content: @escaping () -> Content) {
        _isRefreshing = isRefreshing
        self.showsIndicators = showsIndicators
        self.loadingViewBackgroundColor = loadingViewBackgroundColor
        self.threshold = threshold
        self.refreshAction = refreshAction
        self.progress = progress
        self.content = content
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: showsIndicators) {
            ZStack {
                VStack(spacing: 0) {
                    /// ScrollView无法修改spacing content与GeometryReader存在默认间距8 所以这里增加VStack
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: PPOffsetPreferenceKey.self,
                            value: proxy.frame(in: .named(PPOffsetSpaceName)).origin
                        )
                    }
                    .frame(width: 0.1, height: 0.1)
                    
                    Spacer()
                }
                
                VStack(spacing: 0) {
                    ZStack {
                        Rectangle()
                            .foregroundColor(loadingViewBackgroundColor)
                            .frame(height: threshold)
                        progress(state)
                    }
                    .padding(.top, state.holdRefreshView ? 0 : offset-threshold)
                    
                    content()
                }
            }
        }
        .ignoresSafeArea(.keyboard) /// 忽视其他界面弹起键盘导致的底部异常高度问题
        .coordinateSpace(name: PPOffsetSpaceName)
        .onPreferenceChange(PPOffsetPreferenceKey.self) { offsetChange($0) }
        .onChange(of: state) { value in
            Task { @MainActor in
                if value == .loading { await refreshProcess() }
            }
        }
        .onChange(of: isRefreshing) { value in
            Task { @MainActor in
                withAnimation(.smooth) { state = value ? .loading : .waiting }
            }
        }
    }
    
    private func offsetChange(_ off: CGPoint) {
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
    
    @MainActor private func refreshProcess() async {
        await refreshAction()
        await refreshEnd()
    }
    
    @MainActor private func refreshEnd() async {
        /// Delay of 0.35 seconds (1 second = 1_000_000_000 nanoseconds)
        try? await Task.sleep(nanoseconds: 350_000_000)
        self.state = .finishing
        /// Delay of 1 seconds
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isRefreshing = false
    }
    
}
