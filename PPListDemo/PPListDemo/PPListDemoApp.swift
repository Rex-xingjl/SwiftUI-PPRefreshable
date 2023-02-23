//
//  PPListDemoApp.swift
//  PPListDemo
//
//  Created by Rex on 2023/2/21.
//

import SwiftUI

@main
struct PPListDemoApp: App {

    var body: some Scene {
        WindowGroup {
            TabView {
                asyncView  // async
                blockView  // block
            }
        }
    }
    
    var asyncView: some View {
        NavigationView {
            ListView(manager: ListManager(.async))
                .navigationTitle("AsyncList")
                .navigationBarTitleDisplayMode(.inline)
        }
        .introspectNavigationController { setNaviBar(by: $0) }
        .tabItem {
            Image(systemName: "a.circle")
            Text(verbatim: "List")
        }
    }
    
    var blockView: some View {
        NavigationView {
            ListView(manager: ListManager(.block))
                .navigationTitle("BlockList")
                .navigationBarTitleDisplayMode(.inline)
        }
        .introspectNavigationController { setNaviBar(by: $0) }
        .tabItem {
            Image(systemName: "b.circle")
            Text(verbatim: "List")
        }
    }
}

extension PPListDemoApp {
    /// 解决SwiftUI创建的NaviBar会有一个默认的偏移 向上滚动才会出现NaviBar的问题
    /// The NavigationView created by SwiftUI has a default top spacing and does'nt show bar on appear, this function can fix it.
    func setNaviBar(by navi: UINavigationController) {
        navi.view.backgroundColor = .systemBackground
        navi.edgesForExtendedLayout = []

        if #available(iOS 15, *) {
            let barAppearance = UINavigationBarAppearance()
            barAppearance.configureWithOpaqueBackground()
            barAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label]
            barAppearance.backgroundColor = .tertiarySystemBackground
            barAppearance.shadowImage = UIImage()
            barAppearance.shadowColor = .clear
            navi.navigationBar.scrollEdgeAppearance = barAppearance
            navi.navigationBar.shadowImage = UIImage()
            navi.navigationBar.isTranslucent = false
            navi.navigationBar.standardAppearance = barAppearance
        } else {
            navi.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label]
            navi.navigationBar.shadowImage = UIImage()
            navi.navigationBar.isTranslucent = false
            navi.navigationBar.setBackgroundImage(nil, for: .default)
        }
    }
}
