import Vapor
import Nexus
import FileStorage
import LoggingAdvanced
import ErrorHandle

// FileStorage 依赖环境变量：
//  - <prefix>_FILE_STORAGE_DIR: URL
//  - <prefix>_FILE_STORAGE_FILE_EXTENSION: String
//  - <prefix>_FILE_STORAGE_FILE_UNIX_PERMISSION_OWNER_ID: UInt
//  - <prefix>_FILE_STORAGE_FILE_UNIX_PERMISSION_GROUP_ID: UInt
//  - <prefix>_FILE_STORAGE_FILE_UNIX_PERMISSION_RWX: CModeT(UInt16)

public extension Nexus {
    @frozen
    enum DirCreateAction: CustomStringConvertible, Loggerable {
        case noAction
        case createIfNeed(withIntermediateDirectories: Bool = false)
        
        @inlinable
        public var description: String {
            switch self {
            case .noAction: "noAction"
            case .createIfNeed(let withIntermediateDirectories): "createIfNeed(withIntermediates: \(withIntermediateDirectories))"
            }
        }
    }
    
    /// 初始化一个文件加密系统(同步，若初始化失败将直接导致程序崩溃)
    ///
    /// - Parameters:
    ///     - db: 用于存储文件索引的数据库
    ///     - storagePath: 加密文件在文件系统中存储的位置，相对沙盒文件夹中的位置
    ///     - logger: 日志实例，不会直接使用该 logger 的 label，会派生 .filestorage 使用
    ///     - dirCreateAction: 创建动作，可选择自动创建根文件夹或无任何动作
    ///     - debugging: 调试状态，置为 true 则启动调试模式
    func syncMakeFileStorage(
        for db: Environment.DB,
        storagePath: StoragePath,
        logger: Logger,
        dirCreateAction: DirCreateAction = .noAction,
        debugging: Bool = false
    ) -> FileStorage {
        try! asyncResultToSync {
            await self.makeFileStorage(
                for: db,
                storagePath: storagePath,
                logger: logger,
                dirCreateAction: dirCreateAction,
                debugging: debugging
            )
        }
    }
    
    /// 初始化一个文件加密系统(异步)
    ///
    /// - Parameters:
    ///     - db: 用于存储文件索引的数据库
    ///     - storagePath: 加密文件在文件系统中存储的位置，相对沙盒文件夹中的位置
    ///     - logger: 日志实例，不会直接使用该 logger 的 label，会派生 .filestorage 使用
    ///     - dirCreateAction: 创建动作，可选择自动创建根文件夹或无任何动作
    ///     - debugging: 调试状态，置为 true 则启动调试模式
    func makeFileStorage(
        for db: Environment.DB,
        storagePath: StoragePath,
        logger: Logger,
        dirCreateAction: DirCreateAction = .noAction,
        debugging: Bool = false
    ) async -> Res<FileStorage, FileStorageErrcase> {
        let logger = logger.derive(subId: "filestorage")
        let preLogger = logger.derive(subId: "preinit")
        
        preLogger.info("进行接入文件加密系统前置任务", metadata: [
            "storage_path": .data(storagePath),
            "dir_create_action": .data(dirCreateAction)
        ])
        
        let fileStorageParameter = config.fileStorage
        
        preLogger.debug("任务参数", metadata: ["file_storage_parameter": .data(fileStorageParameter)])
        
        guard let key = db.parameter.fileStorageKey else {
            return .failure(FileStorageErrcase.initFailed, "数据库未设置加密密钥，不支持文件加密系统", metadata: ["db_id": .string(db.id.string)], category: .external())
        }
        
        return await .async { () throws(FileStorageErrcase.ErrType) in
            let mainDirPath = FileSystemTools.resolvePath(basePath: fileStorageParameter.dir.path(), append: "./\(storagePath.string)")
            
            switch dirCreateAction {
            case .noAction:
                preLogger.info("不创建目录，默认目录已存在", metadata: ["path": .string(mainDirPath)])
                break
            case .createIfNeed(withIntermediateDirectories: let c):
                let permissionAttributes = try required(throws: FileStorageErrcase.initFailed, "权限信息读取失败", metadata: ["path": .string(mainDirPath)], category: .inherit) {
                    try fileStorageParameter.permission.attributes.get()
                }
                
                var isDirectory: ObjCBool = false
                if !FileManager.default.fileExists(atPath: mainDirPath, isDirectory: &isDirectory) || !isDirectory.boolValue {
                    preLogger.info("目录不存在，正在创建", metadata: ["path": .string(mainDirPath)])
                    try required(throws: FileStorageErrcase.initFailed, "主目录创建失败", category: .internal) {
                        try FileManager.default.createDirectory(
                            atPath: mainDirPath,
                            withIntermediateDirectories: c,
                            attributes: permissionAttributes
                        )
                    }
                } else {
                    preLogger.info("目录已存在，无需创建", metadata: ["path": .string(mainDirPath)])
                }
            }
            
            preLogger.info("接入文件加密系统前置任务完成")
            
            return try await required(throws: FileStorageErrcase.initFailed, category: .inherit) {
                try await FileStorage.new(
                    eventLoop: self.eventLoopGroup.next(),
                    storagePath: mainDirPath,
                    dbConfigure: debugging ? db.testingConfig : db.config,
                    masterKey: key.key,
                    logger: logger,
                    fileExtension: fileStorageParameter.fileExtension,
                    filePermission: fileStorageParameter.permission,
                    debuging: .init(tdeEncrypt: !debugging)
                ).get()
            }
        }
    }
}
