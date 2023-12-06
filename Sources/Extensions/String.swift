import Foundation

extension String {
 @inlinable var cap: String {
  guard let first else { return self }
  if self.count > 1 {
   return first.uppercased() + self[self.index(after: self.startIndex)...]
  } else {
   return self.capitalized
  }
 }
 @inlinable func cased(upper: Bool, cap: Bool, lower: Bool) -> Self {
  upper ? self.uppercased() : cap ? self.cap : lower ? self.lowercased() : self
 }
}
