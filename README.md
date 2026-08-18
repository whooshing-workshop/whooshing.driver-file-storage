# Whooshing 文件存储驱动模块

本项目为 [Whooshing](https://github.com/whooshing-workshop/whooshing) 系统的**文件存储驱动模块**，作为 `WhooshingServer` 与 `FileStorage` 的连接桥梁。它本身不包含文件存储的核心逻辑（核心逻辑由 [whooshing.toolbox-file-storage](https://github.com/whooshing-workshop/whooshing.toolbox-file-storage) 提供），而是专注于为 [WhooshingServer (主 Server 模块)](https://github.com/whooshing-workshop/whooshing.toolbox-server) 提供便捷的 `FileStorage` 接入与初始化扩展功能。

### 特性

- **无缝集成**：将 `whooshing.toolbox-file-storage` 完美集成到 `WhooshingServer` 的环境中。
- **配置驱动**：作为 Server 的驱动，能直接从系统环境变量中自动提取配置参数进行初始化，用户**无需提供任何 Swift 参数来构建配置**。
- **自动化管理**：支持自动管理和创建基础的存储目录，并自动赋予适当的文件系统权限。
- **环境隔离**：区分调试与生产环境，在调试时可自动应用测试用数据库配置并停用 TDE 加密，以便于 Server 模块开发和测试。

----------

### 导入该依赖库

在你的 Package.swift 加入：

``` swift
.package(url: "https://github.com/whooshing-workshop/whooshing.driver-file-storage.git", from: "1.1.0")
```

在依赖模块中引入:

```swift
.product(name: "FileStorageDriver", package: "whooshing.driver-file-storage")
```

在需要的地方:

```swift
import FileStorageDriver
```

--------

### 使用介绍

由于该库是一个依附于主 Server 的驱动模块，因此你需要先拥有 `Whooshing` Server 的实例环境。所有的环境配置均通过环境变量进行传入。

##### 注册 Driver 并启动 Server

要加载这个 Driver 并在 Server 启动时识别相关的环境变量，只需要在调用 `Whooshing.make(...)` 的时候，向 `driverKeys` 数组提供 `FileStorageDriverKey.self`：

```swift
import FileStorageDriver
import WhooshingServer

// 1. 初始化主 Server 模块，并注册文件存储驱动
let whooshing = try await Whooshing.make(
    env: .independentDebug([
        // 在独立测试环境下，通过字典传入环境变量
        // 生产环境下，系统会自动读取宿主机的环境变量，用户无需书写 Swift 配置代码
        "FILESTORAGE_DIR": "~/whooshing-data",
        "FILESTORAGE_FILE_EXTENSION": "enc"
    ]), 
    driverKeys: [FileStorageDriverKey.self]  // <- 注册 Driver，系统将自动解析所需的环境参数
)
```

##### 接入 FileStorage 实例

在拥有 `whooshing` 实例后，可直接调用扩展方法对其进行挂载和实例化：

``` swift
import FileStorage

// 2. 准备依赖的特定上下文（数据库、存储路径等）
let db: Environment.DB = ... 
let storagePath: StoragePath = "my_storage"
let logger = Logger(label: "Driver-Test")

// 3. 异步初始化并接入文件系统
// 系统将提取刚刚从环境变量中解析到的配置信息自动完成建立
let storageResult = await whooshing.makeFileStorage(
    for: db,
    storagePath: storagePath,
    logger: logger,
    dirCreateAction: .createIfNeed(withIntermediateDirectories: true), // 自动创建主文件夹
    debugging: false
)

switch storageResult {
case .success(let fileStorage):
    print("文件系统初始化并接入成功，可以使用 fileStorage 对象")
case .failure(let error):
    print("初始化接入失败: \(error)")
}
```

或者使用同步版本：

``` swift
let fileStorage = whooshing.syncMakeFileStorage(
    for: db,
    storagePath: storagePath,
    logger: logger,
    dirCreateAction: .createIfNeed(withIntermediateDirectories: true),
    debugging: false
)
```

> **注意**: `syncMakeFileStorage` 方法一旦发生初始化错误，将会导致抛出异常或崩溃退出（主要用于程序启动阶段的必须依赖项接入）。如果希望在运行时安全地处理错误，请使用异步的 `makeFileStorage`。

-------

### 运行环境

* **macOS** (> 13.0)
* **iOS** (> 16.0)
* **Linux** (> 20)
* **Swift** (> 6.0)
* **watchOS** (> 6.0)
* **tvOS** (> 13.0)

-------

### 注意事项

- 使用时，必须保证传入的 Server `Environment.DB` 参数中 `fileStorageKey` 已经正确设置，否则将因为缺少主密钥而导致驱动接入失败。
- 驱动系统高度依赖 `WhooshingServer` 的配置解析管道。确保 `FileStorageDriverKey.self` 被正确传入 `driverKeys`，否则系统将无法知道去环境变量中读取相关配置，这会导致随后调用 `makeFileStorage` 时因找不到配置而报错。
- 文件读写以及文件创建需要对文件系统进行操作，请确保运行 Server 的应用拥有足够的权限。

如需了解更多，请参阅模块内的源码注释与文档说明。

------

### 联系与反馈

如有使用问题或建议，请通过 [GitHub Issues](https://github.com/whooshing-workshop/whooshing.driver-file-storage/issues) 提交反馈。

或发至邮箱 [contact@official.whooshings.space](mailto:contact@official.whooshings.space)
