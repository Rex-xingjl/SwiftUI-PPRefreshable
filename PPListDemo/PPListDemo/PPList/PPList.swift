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
    @ViewBuilder var listBody: some View {
        if let refreshAction = refreshAction {
            LazyVStack(spacing: .zero) {
                fixStutter()
                content()
            }.pp_refreshable($isRefreshing) { completion in
                refreshAction(completion)
            }
        } else {
            LazyVStack(spacing: .zero) {
                fixStutter()
                content()
            }.pp_refreshable($isRefreshing) {
                await asyncRefreshAction?()
            }
        }
    }
    
    var listBody_iOS13: some View {
        List {
            content().listRowInsets(EdgeInsets())
        }
        .listStyle(.plain)
        .introspectTableView { table in
            if #available(iOS 15, *) { table.sectionHeaderTopPadding = 0 }
            table.separatorStyle = .none
            table.tableFooterView = UIView()
        }
        .pullToRefresh(isShowing: $isRefreshing) {
            if let refreshAction = refreshAction {
                refreshAction {
                    Task { @MainActor in $isRefreshing.wrappedValue = false }
                }
            } else if let asyncRefreshAction = asyncRefreshAction {
                Task {
                    await asyncRefreshAction()
                    await MainActor.run { $isRefreshing.wrappedValue = false }
                }
            }
        }
    }
    
    /// 解决某些情况下界面闪动问题 是个SwiftUI BUG
    private func fixStutter() -> some View {
        /// https://stackoverflow.com/questions/66523786/swiftui-putting-a-lazyvstack-or-lazyhstack-in-a-scrollview-causes-stuttering-a
        Rectangle().foregroundColor(.clear).frame(height: 1)
    }
}
