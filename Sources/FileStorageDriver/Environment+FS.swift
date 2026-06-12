import WhooshingServer
import Vapor
import FileStorage
import LoggingAdvanced
import AnyCodable

public extension Environment.Config {
    var fileStorage: Environment.FS? { storage[FileStorageDriverKey.self]! }
}

public extension Environment {
    /// FileStorage 文件加密系统的配置参数
    @frozen
    struct FS: Sendable, Hashable, CustomStringConvertible, Loggerable {
        /// 文件存储的主存储目录
        public let dir: String
        /// 所有加密文件的后缀名，仅调试和测试环境下可自定
        public let fileExtension: String
        /// 文件存储系统的 Unix 文件系统权限
        public let permission: FileStorage.UnixPermission
        
        @inlinable
        public init() { self = Self(dir: "~/whooshing-server-testing") }
        
        /// 初始化环境配置，仅在 ``Whooshing.Env`` 为 `.independentDebug(...)` 时才可能使用
        /// 这些参数在非 `.independentDebug(...)` 模式下会自动从环境变量中读取
        /// - Parameters:
        ///     - dir: 该文件存储系统的主目录
        ///     - fileExtension: 所有加密文件的后缀名
        ///     - permission: 该文件系统目录所有内容的 Unix 权限设置
        @inlinable
        public init(
            dir: String,
            fileExtension: String = FileStorage.DefaultCryptoFileExtension,
            permission: FileStorage.UnixPermission = .init()
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
