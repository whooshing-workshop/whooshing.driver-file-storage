import ErrorHandle
import WhooshingServer

public extension Whooshing {
    @frozen
    enum FileStorageErrcase: String, ErrList, Sendable {
        case initFailed = "文件存储系统初始化失败"
    }
}
