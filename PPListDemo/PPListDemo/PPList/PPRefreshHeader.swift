//
//  RefreshHeader.swift
//  PPListDemo
//
//  Created by Rex on 2022/11/17.
//

import SwiftUI
import Lottie

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


