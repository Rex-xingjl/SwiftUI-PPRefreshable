//
//  PPList.swift
//  PPListDemo
//
//  Created by Rex on 2023/2/20.
//

import SwiftUI
import Combine
import Introspect

/// 带头部刷新的List

public struct PPList<Content>: View where Content: View {

    @Binding private var isRefreshing: Bool
    
    private var content: () -> Content
    
    private var refreshAction: ((RefreshCompleted?) -> Void)?
    
    private var asyncRefreshAction: (@Sendable () async -> Void)?
    
    private let feedback = UIImpactFeedbackGenerator(style: .light)
 
    /// 带头部刷新的List
    /// - Parameter isRefreshing: 刷新的状态
    /// - Parameter content: 内容区域
    /// - Parameter refreshAction: 刷新方法(结束回传block)
    public init(isRefreshing: Binding<Bool>, @ViewBuilder content: @escaping () -> Content, refreshAction: @escaping (RefreshCompleted?) -> Void) {
        _isRefreshing = isRefreshing
        self.content = content
        self.refreshAction = refreshAction
    }
    
    /// 带头部刷新的List 【异步】
    /// - Parameter isRefreshing: 刷新的状态
    /// - Parameter content: 内容区域
    /// - Parameter asyncRefreshAction: 异步刷新方法
    public init(isRefreshing: Binding<Bool>, @ViewBuilder content: @escaping () -> Content, asyncRefreshAction: @escaping @Sendable () async -> Void) {
        _isRefreshing = isRefreshing
        self.content = content
        self.asyncRefreshAction = asyncRefreshAction
    }
    
    public var body: some View {
        if #available(iOS 14.0, *) {
            listBody
        } else {
            listBody_iOS13
        }
    }
    
    @available(iOS 14.0, *)
    var listBody: some View {
        PPRefreshScrollView { completion in
            guard !isRefreshing else { completion(); return }
            refreshHandler(completion)
        } content: {
            LazyVStack(spacing: .zero) {
                content()
            }
        }
    }
    
    var listBody_iOS13: some View {
        List {
            content()
        }
        .listStyle(.plain)
        .introspectTableView { table in
            if #available(iOS 15, *) { table.sectionHeaderTopPadding = 0 }
            table.separatorStyle = .none
        }
        .pullToRefresh(isShowing: $isRefreshing) {
            refreshHandler(nil)
        }
    }
    
    func refreshHandler(_ completion: RefreshCompleted?) {
        DispatchQueue.main.async {
            debugPrint("[PPList] begin refreshing")
            $isRefreshing.wrappedValue = true
            feedback.impactOccurred()
        }
        
        if let refreshAction = refreshAction {
            refreshAction {
                DispatchQueue.main.async {
                    debugPrint("[PPList] end refreshing")
                    $isRefreshing.wrappedValue = false
                    completion?()
                }
            }
        } else if let asyncRefreshAction = asyncRefreshAction {
            Task {
                await asyncRefreshAction()
                await MainActor.run {
                    debugPrint("[PPList] end refreshing")
                    $isRefreshing.wrappedValue = false
                    completion?()
                }
            }
        }
    }
}
