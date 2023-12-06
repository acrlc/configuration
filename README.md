A library for logging and identifying processes
```swift
// declare configuration for logging in memory
let log = Configuration.default

// print string with category
log("starting process", for: .info)
// prints - [ Info ] starting process

// add subcategory
// if no category is specified, the filename becomes the category 
log("ending process", with: .info)
// prints - [ Filename Info ] ending process
```
### Acknowledgments
[Chalk](https://www.github.com/mxcl/chalk) is used to color terminal output
