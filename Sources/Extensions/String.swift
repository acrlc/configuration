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

 var spacedOnUppercaseLetters: String {
  guard count > 1 else {
   return self
  }
  var str = self
  var offset: String.Index = index(after: str.startIndex)

  while
   let index = str[offset...].firstIndex(where: { $0.isUppercase }) {
   if str[offset].isLowercase {
    if let nextIndex = str.index(index, offsetBy: -1, limitedBy: str.index(before: str.endIndex)) {
     if !str[nextIndex].isWhitespace {
      str.insert(.space, at: index)
     }
    } else {
     str.insert(.space, at: index)
    }
   }
   guard
    let newOffset = str[offset...].index(
     index,
     offsetBy: 2,
     limitedBy: str.endIndex
    )
   else {
    break
   }
   offset = newOffset
  }
  return str
 }
}
