import Testing
import Vapor
import Foundation
import Cryptos
@testable import Nexus
@testable import FileStorageDriver

let apiClientTokenStr = "jXTz4vTQk0O/XFIjWQIHLC7z9/E0/4VtEb+LkF8IcA4="
let wrongApiClientTokenStr = "9cCat+omad2WPRetG0VdqSdVhBPVz5kXJ2DssJtQshI="
let wrongApiClientToken = SendableSymmKey(key: .init(data: Data(base64Encoded: wrongApiClientTokenStr)!))
let apiClientToken = SendableSymmKey(key: .init(data: Data(base64Encoded: apiClientTokenStr)!))

@Suite("环境变量解析测试集")
struct EnvironmentParsingTests {
    @Test("测试环境变量读取")
    func testEnvironmentDetect() async throws {
        let project = try Environment.Config.parse(prefix: "WHOOSHING_API_SERVICE", driverKeys: [FileStorageDriverKey.self]) { key in [
            "WHOOSHING_API_SERVICE_NAME": "Testing Project",
            "WHOOSHING_API_SERVICE_PORT": "7777",
            "WHOOSHING_API_SERVICE_DOMAIN": "testing.whooshing.space",
            "WHOOSHING_API_SERVICE_MANAGER_URL": "https://example.com",
            "WHOOSHING_API_SERVICE_HOSTNAME": "localhost",
            
            "WHOOSHING_API_SERVICE_LOG_DIRECTORY": "/User/tester/logfile.log",
            
            "WHOOSHING_API_SERVICE_FILE_STORAGE_DIR": "~/testing",
            "WHOOSHING_API_SERVICE_FILE_STORAGE_UNIX_PERMISSION_OWNER_ID": "1001",
            "WHOOSHING_API_SERVICE_FILE_STORAGE_UNIX_PERMISSION_GROUP_ID": "1002",
            "WHOOSHING_API_SERVICE_FILE_STORAGE_UNIX_PERMISSION_RWX": "480",
            
            "WHOOSHING_API_SERVICE_DB_SERVICES_COUNT": "0"
        ][key] }
        
        #expect(project.name == "Testing Project")
        #expect(project.domain == "testing.whooshing.space")
        #expect(project.port == 7777)
        #expect(project.hostname == "localhost")
        
        let fileStoragePara = project.fileStorage
        #expect(fileStoragePara.dir.absoluteString == "~/testing")
        
        guard case let .id(ownerId) = fileStoragePara.permission.owner else {
            throw "Owner Id Invalid"
        }
        
        guard case let .id(groupId) = fileStoragePara.permission.group else {
            throw "Group Id Invalid"
        }
        #expect(ownerId == 1001)
        #expect(groupId == 1002)
        #expect(fileStoragePara.permission.rwxPermissions == [.ownerReadWriteExecute, .groupRead])
        
        #expect(project.dbServices.count == 0)
        #expect(project.managerUrl.absoluteString == "https://example.com")
        
        #expect(project.log.directory.absoluteString == "/User/tester/logfile.log")
    }
    
    @Test("测试环境变量读取2")
    func testEnvironmentDetect2() async throws {
        let project = try Environment.Config.parse(prefix: "WHOOSHING_API_SERVICE", driverKeys: [FileStorageDriverKey.self]) { key in [
            "WHOOSHING_API_SERVICE_NAME": "Testing Project",
            "WHOOSHING_API_SERVICE_PORT": "7777",
            "WHOOSHING_API_SERVICE_DOMAIN": "testing.whooshing.space",
            "WHOOSHING_API_SERVICE_MANAGER_URL": "https://example.com",
            "WHOOSHING_API_SERVICE_HOSTNAME": "localhost",
            
            "WHOOSHING_API_SERVICE_LOG_DIRECTORY": "/User/tester/logfile.log",
            
            "WHOOSHING_API_SERVICE_FILE_STORAGE_DIR": "~/testing",
            "WHOOSHING_API_SERVICE_FILE_STORAGE_UNIX_PERMISSION_OWNER_ID": "1001",
            "WHOOSHING_API_SERVICE_FILE_STORAGE_UNIX_PERMISSION_GROUP_ID": "1002",
            "WHOOSHING_API_SERVICE_FILE_STORAGE_UNIX_PERMISSION_RWX": "480",
            
            "WHOOSHING_API_SERVICE_DB_SERVICES_COUNT": "0"
        ][key] }
        #expect(project.name == "Testing Project")
        #expect(project.domain == "testing.whooshing.space")
        #expect(project.port == 7777)
        #expect(project.hostname == "localhost")
        
        let fileStoragePara = project.fileStorage
        #expect(fileStoragePara.dir.absoluteString == "~/testing")
        
        guard case let .id(ownerId) = fileStoragePara.permission.owner else {
            throw "Owner Id Invalid"
        }
        
        guard case let .id(groupId) = fileStoragePara.permission.group else {
            throw "Group Id Invalid"
        }
        #expect(ownerId == 1001)
        #expect(groupId == 1002)
        
        #expect(fileStoragePara.permission.rwxPermissions == [.ownerReadWriteExecute, .groupRead])
        
        #expect(project.dbServices.count == 0)
        #expect(project.managerUrl.absoluteString == "https://example.com")
    }
    
    @Test("测试环境变量读取3")
    func testEnvironmentDetect3() async throws {
        let project = try Environment.Config.parse(prefix: "WHOOSHING_API_SERVICE", driverKeys: [FileStorageDriverKey.self]) { key in [
            "WHOOSHING_API_SERVICE_NAME": "Testing Project",
            "WHOOSHING_API_SERVICE_PORT": "7777",
            "WHOOSHING_API_SERVICE_MANAGER_URL": "https://example.com",
            "WHOOSHING_API_SERVICE_HOSTNAME": "localhost",
            "WHOOSHING_API_SERVICE_DB_SERVICES_COUNT": "0",
            
            "WHOOSHING_API_SERVICE_FILE_STORAGE_DIR": "~/testing",
            "WHOOSHING_API_SERVICE_FILE_STORAGE_UNIX_PERMISSION_OWNER_ID": "1001",
            "WHOOSHING_API_SERVICE_FILE_STORAGE_UNIX_PERMISSION_GROUP_ID": "1002",
            "WHOOSHING_API_SERVICE_FILE_STORAGE_UNIX_PERMISSION_RWX": "480",
            
            "WHOOSHING_API_SERVICE_LOG_DIRECTORY": "/User/tester/logfile.log"
        ][key] }
        #expect(project.name == "Testing Project")
        #expect(project.domain == nil)
        #expect(project.port == 7777)
        #expect(project.hostname == "localhost")
        #expect(project.dbServices.count == 0)
        #expect(project.managerUrl.absoluteString == "https://example.com")
    }
    
    @Test("测试环境变量读取4")
    func testEnvironmentDetect4() async throws {
        #expect(throws: Environment.Errcase.ErrType.self, performing: {
            let _ = try Environment.Config.parse(prefix: "WHOOSHING_API_SERVICE", driverKeys: [FileStorageDriverKey.self]) { key in [
                "WHOOSHING_API_SERVICE_NAME": "Testing Project",
                "WHOOSHING_API_SERVICE_PORT": "7777",
                "WHOOSHING_API_SERVICE_MANAGER_URL": "https://example.com",
                "WHOOSHING_API_SERVICE_HOSTNAME": "localhost",
                "WHOOSHING_API_SERVICE_DB_SERVICES_COUNT": "0",
                
                "WHOOSHING_API_SERVICE_LOG_DIRECTORY": "/User/tester/logfile.log"
            ][key] }
        })
    }
    
    @Test("测试环境变量读取5")
    func testEnvironmentDetect5() async throws {
        #expect(throws: Environment.Errcase.ErrType.self, performing: {
            let _ = try Environment.Config.parse(prefix: "WHOOSHING_API_SERVICE", driverKeys: [FileStorageDriverKey.self]) { key in [
                "WHOOSHING_API_SERVICE_NAME": "Testing Project",
                "WHOOSHING_API_SERVICE_PORT": "7777",
                "WHOOSHING_API_SERVICE_MANAGER_URL": "https://example.com",
                "WHOOSHING_API_SERVICE_HOSTNAME": "localhost",
                "WHOOSHING_API_SERVICE_DB_SERVICES_COUNT": "0",
                
                "WHOOSHING_API_SERVICE_LOG_DIRECTORY": "/User/tester/logfile.log",
            ][key] }
        })
    }
    
    @Test("测试环境变量读取6")
    func testEnvironmentDetect6() async throws {
        #expect(throws: Environment.Errcase.ErrType.self, performing: {
            let _ = try Environment.Config.parse(prefix: "WHOOSHING_API_SERVICE", driverKeys: [FileStorageDriverKey.self]) { key in [
                "WHOOSHING_API_SERVICE_NAME": "Testing Project",
                "WHOOSHING_API_SERVICE_PORT": "7777",
                "WHOOSHING_API_SERVICE_MANAGER_URL": "https://example.com",
                "WHOOSHING_API_SERVICE_HOSTNAME": "localhost",
                "WHOOSHING_API_SERVICE_DB_SERVICES_COUNT": "0",
                
                "WHOOSHING_API_SERVICE_LOG_DIRECTORY": "/User/tester/logfile.log"
            ][key] }
        })
    }
    
    @Test("测试环境变量读取7")
    func testEnvironmentDetect7() async throws {
        #expect(throws: Environment.Errcase.ErrType.self, performing: {
            let _ = try Environment.Config.parse(prefix: "WHOOSHING_API_SERVICE", driverKeys: [FileStorageDriverKey.self]) { key in [
                "WHOOSHING_API_SERVICE_NAME": "Testing Project",
                "WHOOSHING_API_SERVICE_PORT": "7777",
                "WHOOSHING_API_SERVICE_MANAGER_URL": "https://example.com",
                "WHOOSHING_API_SERVICE_HOSTNAME": "localhost",
                "WHOOSHING_API_SERVICE_DB_SERVICES_COUNT": "0",
                
                "WHOOSHING_API_SERVICE_LOG_DIRECTORY": "/User/tester/logfile.log"
            ][key] }
        })
    }
    
    @Test("测试环境变量读取8")
    func testEnvironmentDetect8() async throws {
        let project = try Environment.Config.parse(prefix: "WHOOSHING_API_SERVICE", driverKeys: [FileStorageDriverKey.self]) { key in [
            "WHOOSHING_API_SERVICE_NAME": "Testing Project",
            "WHOOSHING_API_SERVICE_PORT": "7777",
            "WHOOSHING_API_SERVICE_DOMAIN": "testing.whooshing.space",
            "WHOOSHING_API_SERVICE_MANAGER_URL": "https://example.com",
            "WHOOSHING_API_SERVICE_HOSTNAME": "localhost",
            
            "WHOOSHING_API_SERVICE_LOG_DIRECTORY": "/User/tester/logfile.log",
            
            "WHOOSHING_API_SERVICE_FILE_STORAGE_DIR": "~/testing",
            "WHOOSHING_API_SERVICE_FILE_STORAGE_UNIX_PERMISSION_OWNER_ID": "1001",
            "WHOOSHING_API_SERVICE_FILE_STORAGE_UNIX_PERMISSION_GROUP_ID": "1002",
            "WHOOSHING_API_SERVICE_FILE_STORAGE_UNIX_PERMISSION_RWX": "480",
            
            "WHOOSHING_API_SERVICE_DB_SERVICES_COUNT": "0",
        ][key] }
        #expect(project.name == "Testing Project")
        #expect(project.domain == "testing.whooshing.space")
        #expect(project.port == 7777)
        #expect(project.hostname == "localhost")

        let fileStoragePara = project.fileStorage
        #expect(fileStoragePara.dir.absoluteString == "~/testing")
        
        guard case let .id(ownerId) = fileStoragePara.permission.owner else {
            throw "Owner Id Invalid"
        }
        
        guard case let .id(groupId) = fileStoragePara.permission.group else {
            throw "Group Id Invalid"
        }
        #expect(ownerId == 1001)
        #expect(groupId == 1002)
        #expect(fileStoragePara.permission.rwxPermissions == [.ownerReadWriteExecute, .groupRead])
        
        #expect(project.dbServices.count == 0)
        #expect(project.managerUrl.absoluteString == "https://example.com")
    }
    
    @Test("测试环境变量读取9")
    func testEnvironmentDetect9() async throws {
        #expect(throws: Environment.Errcase.ErrType.self, performing: {
            let _ = try Environment.Config.parse(prefix: "WHOOSHING_API_SERVICE", driverKeys: [FileStorageDriverKey.self]) { key in [
                "WHOOSHING_API_SERVICE_NAME": "Testing Project",
                "WHOOSHING_API_SERVICE_PORT": "7777",
                "WHOOSHING_API_SERVICE_MANAGER_URL": "https://example.com",
                "WHOOSHING_API_SERVICE_HOSTNAME": "localhost",
                "WHOOSHING_API_SERVICE_DB_SERVICES_COUNT": "0",

                "WHOOSHING_API_SERVICE_LOG_DIRECTORY": "/User/tester/logfile.log"
            ][key] }
        })
    }
    
    @Test("测试环境变量读取10")
    func testEnvironmentDetect10() async throws {
        #expect(throws: Environment.Errcase.ErrType.self, performing: {
            let _ = try Environment.Config.parse(prefix: "WHOOSHING_API_SERVICE", driverKeys: [FileStorageDriverKey.self]) { key in [
                "WHOOSHING_API_SERVICE_PORT": "7777",
                "WHOOSHING_API_SERVICE_DOMAIN": "testing.whooshing.space",
                "WHOOSHING_API_SERVICE_MANAGER_URL": "https://example.com",
                "WHOOSHING_API_SERVICE_HOSTNAME": "localhost",
                
                "WHOOSHING_API_SERVICE_LOG_DIRECTORY": "/User/tester/logfile.log",
                
                "WHOOSHING_API_SERVICE_FILE_STORAGE_DIR": "~/testing",
                "WHOOSHING_API_SERVICE_FILE_STORAGE_UNIX_PERMISSION_OWNER_ID": "1001",
                "WHOOSHING_API_SERVICE_FILE_STORAGE_UNIX_PERMISSION_GROUP_ID": "1002",
                "WHOOSHING_API_SERVICE_FILE_STORAGE_UNIX_PERMISSION_RWX": "480",
                
                "WHOOSHING_API_SERVICE_DB_SERVICES_COUNT": "0"
            ][key] }
        })
    }
}

extension String: @retroactive Error {}
