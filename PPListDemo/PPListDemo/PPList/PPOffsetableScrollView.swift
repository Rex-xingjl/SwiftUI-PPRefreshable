//
//  PPOffsetableScrollView.swift
//  PPListDemo
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

fileprivate let OffsetSpaceName: String = "OffsetSpaceName"

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
            GeometryReader { proxy in
                Color.clear.preference(
                    key: PPOffsetPreferenceKey.self,
                    value: proxy.frame(in: .named(OffsetSpaceName)).origin
                )
            }.frame(width: 0, height: 0)
            
            content
        }
        .coordinateSpace(name: OffsetSpaceName)
        .onPreferenceChange(PPOffsetPreferenceKey.self) { offset in
            /// 这里需要主线程回传 规避一些异常情况
            DispatchQueue.main.async { onOffsetChanged(offset) }
        }
        
    }
}
