import Nexus
import ErrorHandle

public extension Nexus {
    @frozen
    enum FileStorageErrcase: String, ErrList, Sendable {
        case initFailed = "文件存储系统初始化失败"
    }
}
