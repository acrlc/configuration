import Chalk
@_exported import struct Components.Subject
import protocol Core.Infallible
import Extensions
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
 public static func log(
  label: String? = nil,
  category: String? = nil,
  level: Logger.Level? = nil
 ) -> Self {
  let label = label ?? `default`.identifier
  assert(label?.wrapped != nil, "label for logger cannot be nil or empty")
  var `default`: Self = .default

  if let category {
   `default`.logger = Logger(
    label: label!,
    metadataProvider:
    Logger.MetadataProvider {
     ["category": .string(category)]
    }
   )
  } else {
   `default`.logger = Logger(label: label!)
  }

  if let level {
   `default`.logger?.logLevel = level
  }

  return `default`
 }

 public var id: Name = .defaultValue
 #if os(iOS) || os(macOS)
 public var name: String { id.formal ?? id.informal ?? id.identifier! }
 #else
 public var name: String? { id.formal ?? id.informal ?? id.identifier }
 #endif

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
  with category: Components.Subject? = nil
 ) {
  let allow = self.filter == nil
   ? true
   : [subject, category].compactMap { $0 }
    .contains(where: { self.filter!($0) })
  if allow {
   lazy var string =
    input.map(String.init(describing:)).joined(separator: separator)

   if let logger {
    if let level: Logger.Level = {
     switch category {
     case .some(let category):
      switch category {
      case .info: return .info
      case .error: return .error
      case .warning: return .warning
      case .debug: return .debug
      case .critical: return .critical
      case .trace: return .trace
      default: break
      }
      fallthrough
     default:
      guard let subject else {
       return .info
      }
      switch subject {
      case .info: return .info
      case .error: return .error
      case .warning: return .warning
      case .debug: return .debug
      case .critical: return .critical
      case .trace: return .trace
      default: return nil
      }
     }
    }() {
     logger.log(level: level, "\(string)")
    }
   }
   if !self.silent {
    let fixedSubject = subject?.simplified
    let fixedCategory = category?.simplified
    let isError = [subject, category].contains(.error)
    let isSuccess = [subject, category].contains(.success)
    let header = subject == nil
     ? .empty
     : subject!.categoryDescription(
      self, for: fixedSubject, with: fixedCategory
     )
    let message =
     "\(string, color: isError ? .red : isSuccess ? .green : .default)"

    print(header + .space + message, terminator: terminator)
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

 @frozen
 struct Name: Infallible, Hashable {
  public static var defaultValue = Self()
  init(
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
