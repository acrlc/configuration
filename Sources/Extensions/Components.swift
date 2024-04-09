import enum Chalk.Color

public extension Components.Subject {
 static let info: Self = "info"
 static let debug: Self = "debug"
 static let fault: Self = "fault"
 static let database: Self = "database"
 static let function: Self = "function"
 static let task: Self = "task"
 static let detail: Self = "detail"
 static let property: Self = "property"
 static let error: Self = "error"
 static let warning: Self = "warning"
 static let session: Self = "session"
 static let queue: Self = "queue"
 static let service: Self = "service"
 static let test: Self = "test"
 static let view: Self = "view"
 static let cache: Self = "cache"
 static let leaf: Self = "leaf"
 static let migration: Self = "migration"
 static let command: Self = "command"
 static let success: Self = "success"
 static let failure: Self = "failure"
 static let result: Self = "result"
 static let notice: Self = "notice"
 static let note: Self = "note"
}

extension Components.Subject {
 var color: Chalk.Color {
  switch self {
  case .info, .database, .function, .detail, .property: .cyan
  case .error, .session, .queue, .service, .fault: .red
  case .test, .view, .cache, .leaf, .result, .success: .green
  case .migration, .failure, .notice, .note: .magenta
  case .task, .command, .warning: .yellow
  default: .default
  }
 }

 @usableFromInline
 var simplified: Self {
  let string = rawValue
  if let last = string.split(separator: "/").last {
   return Self(
    stringLiteral: String(
     last.split(separator: .period).first
      .unsafelyUnwrapped
    )
   )
  } else {
   return Self(
    stringLiteral: String(
     string.split(separator: .period).first
      .unsafelyUnwrapped
    )
   )
  }
 }

 @usableFromInline
 func categoryDescription(
  _ config: Configuration,
  for category: Components.Subject? = nil,
  with subcategory: Components.Subject? = nil
 ) -> String {
  switch (category, subcategory) {
  case (.some(let category), .some(let subcategory)):
   let upper = config.uppercase
   let cap = config.capitalize
   let lower = config.lowercase
   let cat =
    category.rawValue.cased(upper: upper, cap: cap, lower: lower)
     .spacedOnUppercaseLetters
   let sub =
    subcategory.rawValue.cased(upper: upper, cap: cap, lower: lower)
     .spacedOnUppercaseLetters
   return
    """
    [ \(cat, color: category.color, style: .bold) \
    \(sub, color: subcategory.color, style: .bold) ]
    """
  case (let .some(category), nil):
   let cat = category.rawValue.cased(
    upper: config.uppercase, cap: config.capitalize, lower: config.lowercase
   ).spacedOnUppercaseLetters
   return "[ \(cat, color: category.color, style: .bold) ]"
  case (nil, .some(let subcategory)):
   let upper = config.uppercase
   let cap = config.capitalize
   let lower = config.lowercase
   let cat =
    rawValue.cased(upper: upper, cap: cap, lower: lower)
     .spacedOnUppercaseLetters
   let sub =
    subcategory.rawValue.cased(upper: upper, cap: cap, lower: lower)
     .spacedOnUppercaseLetters
   return
    """
    [ \(cat, color: color, style: .bold) \
    \(sub, color: subcategory.color, style: .bold) ]
    """
  // TODO: Cover prefix / suffix
  default:
   let cat = rawValue.cased(
    upper: config.uppercase, cap: config.capitalize, lower: config.lowercase
   ).spacedOnUppercaseLetters
   return "[ \(cat, style: .bold) ]"
  }
 }
}

