# SwiftUI-PPRefreshable

Available in iOS14+, add refreshable for view （using in a million-user APP）

可在iOS14+版本使用的给视图添加刷新样式（已在百万用户的项目中使用）

# How to use

block style

```swift

PPList(isRefreshing: $viewModel.model.isRefershing) {
    content
} refreshAction: { completion in
    refreshFunction(completion)
}

```

async style

```swift

PPList(isRefreshing: $viewModel.model.isRefershing) {
   content
} asyncRefreshAction: {
    await asyncRefreshFuction()
}

```

Any other views want to refreshable？

```swift

LazyVGrid(columns: itemLayouts, spacing: 0) {
    content
}.pp_refreshable($viewModel.model.isRefershing) { completion in
    refreshFunction(completion)
}

```

# Sight

You can modify the animation and other features in the projects

https://user-images.githubusercontent.com/18180671/223914857-adbf01a4-2f40-4fe7-bde6-9f0b18959b8d.mov



