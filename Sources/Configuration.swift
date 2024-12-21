import Chalk
@_exported import struct Components.Subject
import protocol Core.Infallible
import Extensions
import class Foundation.FileHandle
import class Foundation.FileManager
import struct Foundation.Calendar
import struct Foundation.Date
import struct Foundation.Data
#if canImport(os.log)
import func os.os_log
import class os.OSLog
import struct os.OSLogMessage
import struct os.OSLogType
#endif
import Logging

@dynamicMemberLookup
public struct Configuration: Identifiable {
 public enum LabelCase { case capital, upper, lower }
 public init() {}
 public init(
  case labelCase: LabelCase = .capital,
  silent: Bool = false
 ) {
  self.silent = silent
  self.labelCase = labelCase
 }

 public init(id name: ID) { self.id = name }

 public static var `default` = Configuration()
 public static func `default`(
  id: String? = nil, informal: String? = nil, formal: String? = #fileID
 ) -> Self {
  var copy: Self = Configuration()
  copy.id = Name(
   id: id,
   formal: formal,
   informal: informal ?? formal?.lowercased()
  )
  `default` = copy
  return copy
 }

 final class LogHandler: Logging.LogHandler {
  init(id: Configuration.ID) {
   self.id = id
  }

  subscript(metadataKey key: String) -> Logging.Logger.Metadata.Value? {
   get { metadata[key] }
   set { metadata[key] = newValue }
  }

  var id: Configuration.ID
  var metadata: Logging.Logger.Metadata = .empty
  var logLevel: Logging.Logger.Level = .trace

  #if canImport(os.log)
  lazy var osLog = OSLog(
   subsystem: metadata["subsystem"]?.description ?? .empty,
   category: metadata["category"]?.description ?? .empty
  )

  func osLogType(_ logLevel: Logger.Level) -> OSLogType {
   switch logLevel {
   case .trace: .default
   case .debug: .debug
   case .info, .notice, .warning: .info
   case .error: .error
   case .critical: .fault
   }
  }
  #endif

  #if os(macOS)
  struct OutputStream: TextOutputStream {
   unowned let handler: LogHandler
   var id: Configuration.ID { handler.id }

   var basePath: String {
    // TODO: warn about unique identifier requirement here
    // and create platform specific paths
    "Library/Logs/\(id.identifier ?? id.formal ?? id.informal!).log"
   }

   let fm = FileManager.default
   var outputPath: String {
    fm.homeDirectoryForCurrentUser.appendingPathComponent(basePath).path
   }

   func write(_ message: String) {
    do {
     if !fm.fileExists(atPath: outputPath) {
      try fm.createFile(atPath: outputPath, contents: Data())
       .throwing(reason: "unable to create log file for path: \(outputPath)")
     }
     let handle = try FileHandle(forWritingAtPath: outputPath).throwing(
      reason: "unable to initialize file handle for path: \(outputPath)"
     )
     handle.seekToEndOfFile()
     handle.write(message.data(using: .utf8)!)
     handle.closeFile()
    } catch {
     return handler.log(
      level: .critical,
      message: "\(error.message)",
      metadata: nil,
      source: id.formal ?? id.identifier!,
      file: #fileID, function: #function, line: #line
     )
    }
   }
  }
  #endif

  #if os(macOS)
  lazy var outputStream = OutputStream(handler: self)
  #endif

  private lazy var calendar = Calendar(identifier: .gregorian)

  enum Month: Int {
   case
    january = 1,
    february,
    march,
    april,
    may,
    june,
    july,
    august,
    september,
    october,
    november,
    december

   var name: String { "\(self)" }
   var abbreviation: Substring { name.prefix(3) }
  }

  func log(
   level: Logger.Level, message: Logger.Message, metadata _: Logger.Metadata?,
   source _: String,
   file _: String,
   function _: String,
   line _: UInt
  ) {
   #if canImport(os.log)
   os_log(osLogType(level), log: osLog, "\(message.description, privacy: .public)")
   #if os(macOS)
   if level >= .error {
    let header: String = {
     let comp = calendar.dateComponents(
      [.month, .day, .hour, .minute, .second], from: Date()
     )
     let month = Month(rawValue: comp.month!)!.abbreviation.capitalized
     return "\(month) \(comp.day!) \(comp.hour!):\(comp.minute!):\(comp.second!):"
    }()
    print(header, message.description, terminator: "\n", to: &outputStream)
   }
   #endif
   #else
   #warning("System logging is not currently implemented on this platform")
   #endif
  }
 }

 public static func log(
  label: String? = nil,
  subsystem: String? = nil,
  category: String? = nil,
  level: Logger.Level? = nil,
  filePath _: String = #file,
  fileID: String = #fileID
 ) -> Self {
  let label = label ?? `default`.identifier?.wrapped ?? fileID
  assert(label.wrapped != nil, "label for logger cannot be nil or empty")
  var `default`: Self = .default
  let logHandler = Configuration.LogHandler(id: `default`.id)
  var logger = Logger(
   label: label,
   metadataProvider: Logger.MetadataProvider { logHandler.metadata }
  )

  if let level { logHandler.logLevel = level }
  if let subsystem {
   logHandler[metadataKey: "subsystem"] = .string(subsystem)
   lazy var subsystem = subsystem.casing(.camel)
   logHandler.id.identifier?.append(".\(subsystem)")
   logHandler.id.informal?.append(".\(subsystem)")
  }
  if let category {
   logHandler[metadataKey: "category"] = .string(category)
   lazy var category = category.casing(.camel)
   logHandler.id.identifier?.append(".\(category)")
   logHandler.id.informal?.append(".\(category)")
  }

  logger.handler = logHandler
  `default`.logger = logger

  return `default`
 }

 public func log(
  label: String? = nil,
  subsystem: String? = nil,
  category: String? = nil,
  level: Logger.Level? = nil,
  filePath: String = #file,
  fileID: String = #fileID
 ) -> Self {
  Self.log(
   label: label, subsystem: subsystem, category: category, level: level,
   filePath: filePath,
   fileID: fileID
  )
 }

 public var id: Name = .defaultValue
 /// The resolved name of the configuration.
 /// - Warning: throws fatal error if
 public var name: String {
  if let name = id.formal ?? id.informal {
   name
  } else if let id = id.identifier {
   id
  } else {
   fatalError("name couldn't be resolved, please set the property `id`")
  }
 }

 public var silent = false
 public var labelCase: LabelCase = .capital

 public var capitalize: Bool {
  get { labelCase == .capital }
  set { labelCase = .capital }
 }

 public var uppercase: Bool {
  get { labelCase == .upper }
  set { labelCase = .upper }
 }

 public var lowercase: Bool {
  get { labelCase == .lower }
  set { labelCase = .lower }
 }

 public var filter: ((Subject) -> Bool)?

 public subscript<Value>(
  dynamicMember keyPath: WritableKeyPath<Name, Value>
 ) -> Value {
  get { self.id[keyPath: keyPath] }
  set { self.id[keyPath: keyPath] = newValue }
 }

 public var logger: Logger?

 @_transparent
 public func callAsFunction(
  _ input: Any...,
  separator: String = " ",
  terminator: String = "\n",
  for subject: Components.Subject? = #fileID,
  with category: Components.Subject? = nil,
  source: @autoclosure () -> String? = nil,
  fileID: String = #fileID, filePath _: String = #file, function: String = #function, line: UInt = #line
 ) {
  let allow = self.filter == nil
   ? true
   : [subject, category].compactMap { $0 }
   .contains(where: { self.filter!($0) })

  if allow {
   lazy var string =
    input.map(String.init(describing:)).joined(separator: separator)
   lazy var fixedSubject = subject?.simplified
   lazy var fixedCategory = category?.simplified
   lazy var isError = [subject, category].contains(.error)
   lazy var isSuccess = [subject, category].contains(.success)
   lazy var header = subject == nil
    ? .empty
    : subject!.categoryDescription(
     self, for: fixedSubject, with: fixedCategory
    )
   lazy var message =
    "\(string, color: isError ? .red : isSuccess ? .green : .default)"

   lazy var output = header + .space + message

   if let logger {
    let level: Logger.Level? = {
     switch category {
     case let .some(category):
      switch category {
      case .error: return .error
      case .warning: return .warning
      case .debug: return .debug
      case .notice: return .notice
      case .critical, .fault: return .critical
      case .trace: return .trace
      default: break
      }
      fallthrough
     default:
      switch subject {
      case .error: return .error
      case .warning: return .warning
      case .debug: return .debug
      case .notice: return .notice
      case .critical, .fault: return .critical
      case .trace: return .trace
      default: return nil
      }
     }
    }()
    logger.log(
     level: level ?? logger.logLevel, "\(output)",
     source: source(),
     file: fileID, function: function, line: line
    )
   }
   if !self.silent {
    #if canImport(os.log)
    if logger == nil {
     print(output, terminator: terminator)
    }
    #else
    print(output, terminator: terminator)
    #endif
   }
  }
 }
}

public extension Configuration {
 init(
  identifier: (any CustomStringConvertible)?,
  _ formal: (any CustomStringConvertible)?,
  _ informal: (any CustomStringConvertible)?
 ) {
  self.init(
   id:
   Name(
    id: identifier?.description,
    formal: formal?.description,
    informal: informal?.description
   )
  )
 }
}

// MARK: - Extensions
#if canImport(CoreFoundation)
import CoreFoundation
import class Foundation.Bundle
import class Foundation.ProcessInfo

public extension Configuration.Name {
 static var appName: String? {
  #if os(WASI) || os(Windows) || os(Linux)
  nil
  #else
  Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ??
   Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ??
   Bundle.main.infoDictionary?[kCFBundleExecutableKey as String] as? String
  #endif
 }

 static var bundleName: String? {
  #if os(WASI) || os(Windows) || os(Linux)
  nil
  #elseif os(macOS) || os(iOS)
  Bundle.main.bundleIdentifier
  #endif
 }
}
#else
import class Foundation.Bundle
import class Foundation.ProcessInfo

extension Configuration.Name {
 static var appName: String { ProcessInfo.processInfo.processName }
 static var bundleName: String? { Bundle.main.bundleIdentifier }
}
#endif

public extension Configuration {
 var appName: String? { Name.appName }
 var bundleName: String? { Name.bundleName }

 struct Name: Infallible, Hashable {
  public static var defaultValue = Self()
  public init(
   id: String? = nil,
   formal: String? = nil,
   informal: String? = nil
  ) {
   identifier = id ?? Self.bundleName
   self.formal = formal ?? Self.appName
   self.informal =
    informal ?? formal?.lowercased() ?? Self.appName?.lowercased()
  }

  public var identifier: String? = Self.bundleName
  public var formal: String? = Self.appName
  public var informal: String? = Self.appName?.lowercased()
 }
}
