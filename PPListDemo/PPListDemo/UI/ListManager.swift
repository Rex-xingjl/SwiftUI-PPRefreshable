//
//  FileListManager.swift
//  PPListDemo
//
//  Created by Rex on 2023/2/21.
//

import Foundation
import Combine

enum ListType: String {
case async
case block
}

class ListManager: ObservableObject {
    
    @Published var model: ListModel
    
    let listType: ListType
    
    init(_ type: ListType, count: Int = 100) {
        listType = type
        model = ListModel(datas: (0...count).compactMap { "\(type.rawValue) : \($0)" })
    }
}
