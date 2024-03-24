import Chalk
import Extensions
import protocol Core.Infallible
@_exported import struct Components.Subject
import struct OSLog.Logger

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
 public static func `default`(category: String) -> Self {
  var `default`: Self = .default
  `default`.logger = Logger(subsystem: `default`.identifier, category: category)
  return `default`
 }

 public var id: Name = .defaultValue
 public var name: String { id.formal ?? id.informal ?? id.identifier }
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
  let allow = self.filter == nil ? true :
   [subject, category].compactMap { $0 }
   .contains(where: { self.filter!($0) })
  if !self.silent, allow {
   let string =
    input.map(String.init(describing:)).joined(separator: separator)
   logger?.log(level: {
    switch category {
    case .some(let category):
     switch category {
     case .info: return .info
     case .error: return .error
     case .debug: return .debug
     case .fault: return .fault
     default: break
     }
     fallthrough
    default:
     guard let subject else { return .default }
     switch subject {
     case .info: return .info
     case .error: return .error
     case .debug: return .debug
     case .fault: return .fault
     default: return .default
     }
    }
   }(),
   "\(string)")
   #if DEBUG
   let fixedSubject = subject?.simplified
   let fixedCategory = category?.simplified
   let isError = [subject, category].contains(.error)
   let isSuccess = [subject, category].contains(.success)
   let header = subject == nil ? .empty :
    subject!.categoryDescription(
     self, for: fixedSubject, with: fixedCategory
    )
   let message =
    "\(string, color: isError ? .red : isSuccess ? .green : .white)"

   print(header + .space + message, terminator: terminator)
   #endif
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
  nil // fatalError("\(#function) not implemented, must be entered manually")
  #else
  Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ??
   Bundle.main.infoDictionary?[kCFBundleExecutableKey as String] as? String
  #endif
 }

 static var bundleName: String {
  #if os(WASI) || os(Windows)
  "" // fatalError("\(#function) not implemented, must be entered manually")
  #else
  Bundle.main.bundleIdentifier ?? {
   let info = ProcessInfo.processInfo
   return info.fullUserName
    .split(separator: .space).map { $0.lowercased() }
    .joined(separator: .period)
    .appending(.period + info.processName)
  }()
  #endif
 }

 #if os(iOS)
 @usableFromInline
 static var bundleName: String {
  Bundle.main.bundleIdentifier ?? ProcessInfo.processInfo.processName
 }
 #endif
}
#else
import class Foundation.Bundle
import class Foundation.ProcessInfo
extension Configuration.Name {
 static var appName: String { ProcessInfo.processInfo.processName }
 static var bundleName: String {
  Bundle.main.bundleIdentifier ?? {
   let info = ProcessInfo.processInfo
   return info.fullUserName
    .split(separator: .space).map { $0.lowercased() }
    .joined(separator: .period)
    .appending(.period + info.processName)
  }()
 }
}
#endif

public extension Configuration {
 var appName: String? { Name.appName }
 var bundleName: String { Name.bundleName }

 @frozen struct Name: Infallible, Hashable {
  public static var defaultValue = Self()
  init(
   id: String? = nil,
   formal: String? = nil,
   informal: String? = nil
  ) {
   self.identifier = id ?? Self.bundleName
   self.formal = formal ?? Self.appName
   self.informal =
    informal ?? formal?.lowercased() ?? Self.appName?.lowercased()
  }

  public var identifier: String = Self.bundleName
  public var formal: String? = Self.appName
  public var informal: String? = Self.appName?.lowercased()
 }
}
