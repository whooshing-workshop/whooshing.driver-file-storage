import Nexus
import Vapor
import SystemPackage
import FileStorage
import OrderedCollections
import Collections
import LoggingAdvanced

public enum FileStorageDriverKey: Environment.DriverKey {
    public typealias Value = Environment.FS
    public static let label = "file_storage"
    public static let valueType: Environment.Types = .template(Environment.FS.self)
    public static func loggerStrategies(for directory: URL) -> [LoggerStrategy] {
        do {
            return [
                try .init(
                    label: "storage",
                    level: .info,
                    config: .file(
                        match: { $0.contains("filestorage") },
                        directory: directory.appendingPathComponent("storage_logs"),
                        name: "storage.log"
                    )
                )
            ]
        } catch {
            fatalError("创建 storage.log 策略失败: \(error)")
        }
    }
}

extension Environment.FS: Environment.Template {
    @inlinable
    public static func withEnv(dic origin: inout OrderedDictionary<String, Environment.Types>) {
        origin["dir"] = .url()
        origin["unix_permission_owner_id"] = .int(CUnsignedLong.self)
        origin["unix_permission_group_id"] = .int(CUnsignedLong.self)
        origin["unix_permission_rwx"] = .int(CModeT.self)
    }
    
    @inlinable
    public init(data: [String : Any], driverKeys: [any Environment.DriverKey.Type], extra: [String : Any]) {
        self.dir = data["dir"] as! URL
        self.fileExtension = FileStorage.DefaultCryptoFileExtension
        self.permission = .init(
            owner: .id(data["unix_permission_owner_id"] as! CUnsignedLong),
            group: .id(data["unix_permission_group_id"] as! CUnsignedLong),
            rwx: .init(rawValue: data["unix_permission_rwx"] as! CModeT)
        )
    }
}
