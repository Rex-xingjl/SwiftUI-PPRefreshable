//
//  PPRefreshScrollView.swift
//  PPListDemo
//
//  Created by Rex on 2022/11/25.
//

import SwiftUI
import Combine

@available(iOS 14.0, *)
public struct PPRefreshScrollView<Content>: View where Content: View {
    
    let onRefresh: OnRefresh

    let content: () -> Content
    
    public init(onRefresh: @escaping OnRefresh, @ViewBuilder content: @escaping () -> Content) {
        self.onRefresh = onRefresh
        self.content = content
    }
    
    public var body: some View {
        PPRefreshableScrollView(onRefresh: onRefresh, progress: { progress in
            PPRefreshHeader(play: .constant(progress != .waiting))
                .frame(height: defaultRefreshThreshold)
        }, content: content)
    }
}
