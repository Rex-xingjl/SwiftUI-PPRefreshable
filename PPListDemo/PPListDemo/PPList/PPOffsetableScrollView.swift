//
//  PPOffsetableScrollView.swift
//  PPUI
//
//  Created by Rex on 2023/2/7.
//

import Foundation
import SwiftUI

// 可以回传offset的ScrollView

public struct PPOffsetPreferenceKey: PreferenceKey {
    
    public static var defaultValue: CGPoint = .zero
    
    public static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { }
}

fileprivate let PPOffsetSpaceName: String = "OffsetSpaceName"

@available(iOS 14.0, *)
public struct PPOffsetableScrollView<T: View>: View {

    let axes: Axis.Set
    let showsIndicator: Bool
    let onOffsetChanged: (CGPoint) -> Void
    let content: T
    
    public init(axes: Axis.Set = .vertical,
                showsIndicator: Bool = true,
                onOffsetChanged: @escaping (CGPoint) -> Void = { _ in },
                @ViewBuilder content: () -> T) {
        self.axes = axes
        self.showsIndicator = showsIndicator
        self.onOffsetChanged = onOffsetChanged
        self.content = content()
    }

    public var body: some View {
        ScrollView(axes, showsIndicators: showsIndicator) {
            /// ScrollView无法修改spacing content与GeometryReader存在默认间距8 所以这里增加VStack
            VStack(spacing: 0) {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: PPOffsetPreferenceKey.self,
                        value: proxy.frame(in: .named(PPOffsetSpaceName)).origin
                    )
                }.frame(width: 0, height: 0)
                
                content
            }
        }
        .coordinateSpace(name: PPOffsetSpaceName)
        .onPreferenceChange(PPOffsetPreferenceKey.self) { offset in
            /// 这里需要主线程回传 规避一些线程异常情况
            Task { @MainActor in onOffsetChanged(offset) }
        }
        .ignoresSafeArea(.keyboard) /// 忽视其他界面弹起键盘导致的底部异常高度问题
    }
}
