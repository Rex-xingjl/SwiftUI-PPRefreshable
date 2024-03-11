//
//  ListView.swift
//  PPListDemo
//
//  Created by Rex on 2023/2/21.
//

import SwiftUI
import Combine

struct ListView: View {
    @ObservedObject var manager: ListManager

    var body: some View {
        switch manager.listType {
        case .async: asyncList
        case .block: blockList
        }
    }
    
    // MARK: - 异步方式：搭配Combine使用很好 - AsyncAction：enjoy with Combine would be better(necessary)
    
    var asyncList: some View {
        PPList(isRefreshing: $manager.model.isRefershing) {
           content
        } asyncRefreshAction: {
            await withCheckedContinuation { continuation in
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    continuation.resume()
                }
            }
        }
        .onAppear {
            manager.model.isRefershing = true
        }
    }
    
    // MARK: - 回传方式：搭配block处理结束更自由 - BlockAction：Freedom and Sweet Air
    
    var blockList: some View {
        PPList(isRefreshing: $manager.model.isRefershing) {
            content
        } refreshAction: { completion in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                completion?()
            }
        }
    }
    
    // MARK: - 列表内容 - content of List
    
    var content: some View {
        ForEach(manager.model.datas, id: \.self) { item in
            NavigationLink(destination: Text(verbatim: item)) {
                HStack {
                    Text(item)
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .padding(16)
            }
            .foregroundColor(.secondary)
        }
    }
}
