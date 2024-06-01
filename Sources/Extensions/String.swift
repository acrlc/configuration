import Foundation

extension String {
 @inlinable
 var cap: String {
  guard let first else {
   return self
  }
  if count > 1 {
   return first.uppercased() + self[index(after: startIndex)...]
  } else {
   return capitalized
  }
 }

 @inlinable
 func cased(upper: Bool, cap: Bool, lower: Bool) -> Self {
  upper ? uppercased() : cap ? self.cap : lower ? lowercased() : self
 }
}
