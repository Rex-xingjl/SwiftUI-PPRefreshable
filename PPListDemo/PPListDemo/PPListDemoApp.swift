//
//  PPListDemoApp.swift
//  PPListDemo
//
//  Created by Rex on 2023/2/21.
//

import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        .all
    }
}

@main
struct PPListDemoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let amanager = ListManager(.async)
    let bmanager = ListManager(.block)

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
            ListView(manager: amanager)
                .navigationTitle("AsyncList")
                .navigationBarTitleDisplayMode(.inline)
        }
        .tabItem {
            Image(systemName: "a.circle")
            Text(verbatim: "List")
        }
    }
    
    var blockView: some View {
        NavigationView {
            ListView(manager: bmanager)
                .navigationTitle("BlockList")
                .navigationBarTitleDisplayMode(.inline)
        }
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
