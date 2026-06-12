import Vapor
import SystemPackage
import FileStorage
import OrderedCollections
import Collections
import WhooshingServer

public enum FileStorageDriverKey: Environment.DriverKey {
    public typealias Value = Environment.FS?
    public static let label = "file_storage"
    public static let isOptional = true
    public static let valueType: Environment.Types = .dataTemplate(Environment.FS.self)
}

extension Environment.FS: Environment.Template {
    @inlinable
    public static func withEnv(dic origin: inout OrderedDictionary<String, Environment.Types>) {
        origin["dir"] = .string
        origin["unix_permission_owner_id"] = .int(CUnsignedLong.self)
        origin["unix_permission_group_id"] = .int(CUnsignedLong.self)
        origin["unix_permission_rwx"] = .int(CModeT.self)
    }
    
    @inlinable
    public init(data: [String : Any], driverKeys: [any Environment.DriverKey.Type], extra: [String : Any]) {
        self.dir = data["dir"] as! String
        self.fileExtension = FileStorage.DefaultCryptoFileExtension
        self.permission = .init(
            owner: .id(data["unix_permission_owner_id"] as! CUnsignedLong),
            group: .id(data["unix_permission_group_id"] as! CUnsignedLong),
            rwx: .init(rawValue: data["unix_permission_rwx"] as! CModeT)
        )
    }
}
