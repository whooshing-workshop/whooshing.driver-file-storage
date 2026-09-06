# Whooshing 文件存储驱动模块

本项目为 [Whooshing](https://github.com/whooshing-workshop/whooshing) 系统的**文件存储驱动模块**，作为 `Nexus` 与 `FileStorage` 的连接桥梁。它本身不包含文件存储的核心逻辑（核心逻辑由 [whooshing.toolbox-file-storage](https://github.com/whooshing-workshop/whooshing.toolbox-file-storage) 提供），而是专注于为 [whooshing.nexus (服务模块核心)](https://github.com/whooshing-workshop/whooshing.nexus) 提供便捷的 `FileStorage` 配置解析、接入与初始化扩展功能。

### 特性

- **无缝集成**：将 `whooshing.toolbox-file-storage` 完美集成到 `Nexus` 的环境中，通过 `nexus.makeFileStorage(...)` 一步接入。
- **配置驱动**：作为 Nexus 的驱动（`FileStorageDriverKey`），能直接从系统环境变量中自动提取配置参数进行初始化，用户**无需提供任何 Swift 参数来构建配置**。
- **自动化管理**：支持自动创建存储主目录（含中间目录），并按配置赋予 Unix 文件系统权限（owner / group / rwx）。
- **独立日志分流**：自动为文件存储子系统申请 `storage_logs/storage.log` 日志轮转文件。
- **环境隔离**：区分调试与生产环境，在调试时自动应用测试用数据库配置并停用 TDE 加密，以便于服务模块开发和测试。
- **Vapor Content 扩展**：为 `StoragePath`、`FileStorage.UnixPermission` 等类型补充 `Content` 实现，可直接作为请求体 / 响应体编解码。

----------

### 导入该依赖库

在你的 `Package.swift` 加入：

``` swift
.package(url: "https://github.com/whooshing-workshop/whooshing.driver-file-storage.git", from: "1.1.3")
```

在依赖模块中引入:

```swift
.product(name: "FileStorageDriver", package: "whooshing.driver-file-storage")
```

在需要的地方:

```swift
import FileStorageDriver
```

> `FileStorageDriver` 已通过 `@_exported` 重新导出了 `Nexus` 与 `FileStorage`，导入后无需再单独导入这两个模块。

--------

### 使用介绍

由于该库是一个依附于 Nexus 的驱动模块，因此你需要先拥有 `Nexus` 实例。所有的环境配置均通过环境变量进行传入。

##### 注册 Driver 并执行 Bootstrap

要加载这个 Driver 并在启动时识别相关的环境变量，只需要在调用 `Bootstrap.run(...)` 的时候，向 `driverKeys` 数组提供 `FileStorageDriverKey.self`：

```swift
import VaporTube
import FileStorageDriver

// 1. 独立调试模式下，通过 .load(fileStorage:) 伪造文件存储参数
//    生产环境下，系统会自动读取宿主机的环境变量，用户无需书写 Swift 配置代码
let config = Environment.Config(
    id: UUID(),
    name: "my-module",
    port: 6500,
    dbServices: [
        .init(name: "default", dbParameters: [
            .init(
                name: "file_storage",
                user: "postgres",
                password: "password",
                fileStorageKey: SendableSymmKey(key: .init(data: Data(base64Encoded: "UA/0Si+aUkrJou9W2pCDjrTkDBiAfZxdoD1MEFyHP58=")!))
            )
        ])
    ]
).load(fileStorage: Environment.FS(
    dir: URL.homeDirectoryURL.appending(component: "app_file_storage")
))

// 2. 执行 Bootstrap 并注册 Driver，系统将自动解析所需的环境参数
let paras = try await Bootstrap.run(
    .detect(config),
    driverKeys: [FileStorageDriverKey.self],
    logger: Logger(label: "app")
).get()

let tube = try await VaporTube.make(paras).get()
let nexus = Nexus(tube: tube, bootstrap: paras)
```

生产环境下，Driver 会以 `WHOOSHING_FILE_STORAGE` 为前缀读取以下环境变量：

```
WHOOSHING_FILE_STORAGE_DIR=/data/whooshing            # 存储主目录 (URL)
WHOOSHING_FILE_STORAGE_UNIX_PERMISSION_OWNER_ID=1001  # 目录所有者 UID
WHOOSHING_FILE_STORAGE_UNIX_PERMISSION_GROUP_ID=1002  # 目录所属 GID
WHOOSHING_FILE_STORAGE_UNIX_PERMISSION_RWX=480        # 权限位 (十进制 mode_t，480 即 0o740)
```

加密主密钥不属于本驱动的配置，而是随数据库配置一起以 `..._DBS_n_FILE_STORAGE_KEY` 提供，详见 [whooshing.nexus](https://github.com/whooshing-workshop/whooshing.nexus)。

##### 接入 FileStorage 实例

在拥有 `nexus` 实例后，可直接调用扩展方法对其进行挂载和实例化：

``` swift
// 3. 准备依赖的特定上下文（数据库、存储路径等）
let db: Environment.DB = nexus.config.dbServices[0].dbs[0]   // 必须设置了 fileStorageKey
let storagePath: StoragePath = "my_storage"                  // 相对于主目录的子目录
let logger = Logger(label: "app")

// 4. 异步初始化并接入文件系统
// 系统将提取从环境变量中解析到的配置信息自动完成建立
let storageResult = await nexus.makeFileStorage(
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

或者使用同步版本（常用于 `static let` 单例）：

``` swift
extension FileStorage {
    static let `default`: FileStorage = {
        nexus.syncMakeFileStorage(
            for: db,
            storagePath: "default",
            logger: logger,
            dirCreateAction: .createIfNeed(withIntermediateDirectories: true),
            debugging: isIndependentDebug
        )
    }()
}
```

> **注意**: `syncMakeFileStorage` 方法一旦发生初始化错误，将会直接导致程序崩溃退出（主要用于程序启动阶段的必须依赖项接入）。如果希望在运行时安全地处理错误，请使用异步的 `makeFileStorage`。

##### 读取驱动配置

``` swift
let fs: Environment.FS = nexus.config.fileStorage

fs.dir              // 存储主目录
fs.fileExtension    // 加密文件后缀，默认 FileStorage.DefaultCryptoFileExtension，仅独立调试可自定
fs.permission       // FileStorage.UnixPermission
```

-------

### 运行环境

* **macOS** (> 13.0)
* **iOS** (> 16.0)
* **Linux** (> 20)
* **Swift** (> 6.0)
* **watchOS** (> 6.0) **[未测试]**
* **tvOS** (> 13.0) **[未测试]**

-------

### 注意事项

- 使用时，必须保证传入的 `Environment.DB` 参数中 `fileStorageKey` 已经正确设置，否则将因为缺少主密钥而导致驱动接入失败（`FileStorageErrcase.initFailed`）。
- 驱动系统高度依赖 `Nexus` 的配置解析管道。确保 `FileStorageDriverKey.self` 被正确传入 `driverKeys`，否则系统将无法知道去环境变量中读取相关配置，这会导致随后调用 `makeFileStorage` 时因找不到配置而崩溃。
- `debugging: true` 时会使用 `db.testingConfig` 连接数据库并关闭 TDE 加密，请勿在生产环境开启。
- 文件读写以及文件创建需要对文件系统进行操作，请确保运行服务的应用拥有足够的权限。

如需了解更多，请参阅模块内的源码注释与文档说明。

------

### 联系与反馈

如有使用问题或建议，请通过 [GitHub Issues](https://github.com/whooshing-workshop/whooshing.driver-file-storage/issues) 提交反馈。

或发至邮箱 [contact@official.whooshings.space](mailto:contact@official.whooshings.space)
