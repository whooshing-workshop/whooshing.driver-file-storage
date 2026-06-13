import WhooshingServer
import Vapor
import FileStorage
import LoggingAdvanced
import AnyCodable
import NIOFileSystem

public extension Environment.Config {
    /// 文件加密系统的必要参数
    var fileStorage: Environment.FS? { storage[FileStorageDriverKey.self] ?? nil } // 必须写为 ?? nil 而非 storage[XXX]!，否则可能引发崩溃
    
    /// 用于在无依赖 debug (Whooshing.Env.independentDebug) 模式下加载 FileStorage 依赖参数
    ///
    /// 伪造该文件系统所必需的参数
    ///
    /// > 在一般的 .production 或 .debug 模式下，
    /// 这些参数会通过 Whooshing 系统的环境变量解析得到，
    /// 而在独立无依赖运行模式下，需要手动提供
    func load(fileStorage: Environment.FS?) -> Self {
        var new = self
        new.storage[FileStorageDriverKey.self] = fileStorage
        return new
    }
}

public extension Environment {
    /// FileStorage 文件加密系统的配置参数
    @frozen
    struct FS: Sendable, Hashable, CustomStringConvertible, Loggerable {
        /// 文件存储的主存储目录
        public let dir: URL
        /// 所有加密文件的后缀名，仅调试和测试环境下可自定
        public let fileExtension: String
        /// 文件存储系统的 Unix 文件系统权限
        public let permission: FileStorage.UnixPermission
        
        @inlinable
        public init() { self = Self(dir: .homeDirectoryURL.appendingPathComponent("whooshing-server-testing")) }
        
        /// 初始化环境配置，仅在 ``Whooshing.Env`` 为 `.independentDebug(...)` 时才可能使用
        /// 这些参数在非 `.independentDebug(...)` 模式下会自动从环境变量中读取
        /// - Parameters:
        ///     - dir: 该文件存储系统的主目录
        ///     - fileExtension: 所有加密文件的后缀名
        ///     - permission: 该文件系统目录所有内容的 Unix 权限设置
        @inlinable
        public init(
            dir: URL,
            fileExtension: String = FileStorage.DefaultCryptoFileExtension,
            permission: FileStorage.UnixPermission = .init(rwx: [.otherReadWriteExecute, .groupReadWriteExecute, .ownerReadWriteExecute])
        ) {
            self.dir = dir
            self.fileExtension = fileExtension
            self.permission = permission
        }
        
        @inlinable
        public var json: [String: AnyCodable] {[
            "dir": AnyCodable(dir),
            "file_extension": AnyCodable(fileExtension),
            "permission": AnyCodable(permission.json)
        ]}
        
        @inlinable
        public var description: String {
            formatJson(json)
        }
    }
}
