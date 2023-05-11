//
//  PPRefreshable.swift
//
//
//  Created by Rex on 2023/4/23.
//

import Foundation
import SwiftUI

@available(iOS 14.0, *)
public extension View {
    
    /// [block方式] 对视图增加头部刷新
    /// - Parameter isRefreshing: 绑定当前刷新状态值
    /// - Parameter showsIndicators: 是否展示ScrollView的指示器
    /// - Parameter refreshAction: 刷新方法 结束后回调block
    @ViewBuilder func pp_refreshable(_ isRefreshing: Binding<Bool>, showsIndicators: Bool = true, refreshAction: @escaping (RefreshCompleted?) -> Void) -> some View {
        modifier(PPRefreshable(isRefreshing: isRefreshing, showsIndicators: showsIndicators, progress: { state in
            PPRefreshHeader(play: .constant(state != .finishing))
                .frame(height: defaultRefreshThreshold)
        }, refreshAction: refreshAction))
    }
    
    /// [async方式]对视图增加头部刷新
    /// - Parameter isRefreshing: 绑定当前刷新状态值
    /// - Parameter showsIndicators: 是否展示ScrollView的指示器
    /// - Parameter refreshAction: 刷新方法 结束后回调block
    @ViewBuilder func pp_refreshable(_ isRefreshing: Binding<Bool>, showsIndicators: Bool = true, asyncRefreshAction: @escaping @Sendable () async -> Void) -> some View {
        modifier(PPRefreshable(isRefreshing: isRefreshing, showsIndicators: showsIndicators, progress: { state in
            PPRefreshHeader(play: .constant(state != .finishing))
                .frame(height: defaultRefreshThreshold)
        }, asyncRefreshAction: asyncRefreshAction))
    }
}

@available(iOS 14.0, *)
public struct PPRefreshable<Progress>: ViewModifier where Progress: View {
    private let feedback = UIImpactFeedbackGenerator(style: .soft)
    
    @Binding private var isRefreshing: Bool
    private let showsIndicators: Bool
    private let progress: PPRefreshProgressBuilder<Progress>
    
    private var refreshAction: ((RefreshCompleted?) -> Void)?
    private var asyncRefreshAction: (@Sendable () async -> Void)?
    
    public init(isRefreshing: Binding<Bool>, showsIndicators: Bool, @ViewBuilder progress: @escaping PPRefreshProgressBuilder<Progress>, refreshAction: @escaping (RefreshCompleted?) -> Void) {
        _isRefreshing = isRefreshing
        self.showsIndicators = showsIndicators
        self.progress = progress
        self.refreshAction = refreshAction
    }
    
    public init(isRefreshing: Binding<Bool>, showsIndicators: Bool = true, @ViewBuilder progress: @escaping PPRefreshProgressBuilder<Progress>, asyncRefreshAction: @escaping @Sendable () async -> Void) {
        _isRefreshing = isRefreshing
        self.showsIndicators = showsIndicators
        self.progress = progress
        self.asyncRefreshAction = asyncRefreshAction
    }

    public func body(content: Content) -> some View {
        PPRefreshableScrollView(showsIndicators: showsIndicators, loadingViewBackgroundColor: .clear, threshold: defaultRefreshThreshold) { completion in
            guard !isRefreshing else { completion(); return }
            refreshHandler(completion)
        } progress: { state in
            progress(state)
        } content: {
            content
        }
    }
    
    private func refreshHandler(_ completion: RefreshCompleted?) {
        Task { @MainActor in
            $isRefreshing.wrappedValue = true
            feedback.impactOccurred()
        }
        
        if let refreshAction = refreshAction {
            refreshAction {
                Task { @MainActor in
                    $isRefreshing.wrappedValue = false
                    completion?()
                }
            }
        } else if let asyncRefreshAction = asyncRefreshAction {
            Task {
                await asyncRefreshAction()
                await MainActor.run {
                    $isRefreshing.wrappedValue = false
                    completion?()
                }
            }
        }
    }
}
