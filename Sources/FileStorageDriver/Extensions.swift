import Vapor
import FileStorage

extension StoragePath: @retroactive RequestDecodable {}
extension StoragePath: @retroactive ResponseEncodable {}
extension StoragePath: @retroactive AsyncRequestDecodable {}
extension StoragePath: @retroactive AsyncResponseEncodable {}
extension StoragePath: @retroactive Content {}

extension FileStorage.UnixPermission: @retroactive RequestDecodable {}
extension FileStorage.UnixPermission: @retroactive ResponseEncodable {}
extension FileStorage.UnixPermission: @retroactive AsyncRequestDecodable {}
extension FileStorage.UnixPermission: @retroactive AsyncResponseEncodable {}
extension FileStorage.UnixPermission: @retroactive Content {}

extension FileStorage.UnixPermission.User: @retroactive RequestDecodable {}
extension FileStorage.UnixPermission.User: @retroactive ResponseEncodable {}
extension FileStorage.UnixPermission.User: @retroactive AsyncRequestDecodable {}
extension FileStorage.UnixPermission.User: @retroactive AsyncResponseEncodable {}
extension FileStorage.UnixPermission.User: @retroactive Content {}

extension FileStorage.UnixPermission.Group: @retroactive RequestDecodable {}
extension FileStorage.UnixPermission.Group: @retroactive ResponseEncodable {}
extension FileStorage.UnixPermission.Group: @retroactive AsyncRequestDecodable {}
extension FileStorage.UnixPermission.Group: @retroactive AsyncResponseEncodable {}
extension FileStorage.UnixPermission.Group: @retroactive Content {}
