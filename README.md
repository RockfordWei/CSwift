# C Module for Swift, Swift Script and Dynamic Library Call [简体中文](README.zh_CN.md)

Rockford Wei，2017-01-17

Last update: 2018-01-23

This project demonstrates how to call a customized C library in your swift project.
You can clone it from github, or follow the instruction below to generate it step by step.

Furthermore, this demo also shows how to use swift as a script, with examples of calling C api as dynamic libraries.
This practice makes it possible to patch hot fixes for server side swift without stopping the server, theoretically.

## Introduction

There are two C files: CSwift.c and CSwift.h. The objective is to build a CSwift library and export it to Swift.

## Quick Start

Please compile this project with Swift 4.0.3 toolchain.

### Build & Test

```
$ git clone https://github.com/RockfordWei/CSwift.git
$ cd CSwift
$ swift build
$ swift test
```

The sources are written in C while the test program is written in Swift. So if all tests passed, then congratulations! You've already mastered the process to call C api in a Swift source.

## Walk Through

However, even without the sources above, you can still start everything from blank:

### Start From An Empty Folder:

Assume the objective library is still CSwift, then find an empty folder and try these commands in a terminal:

```
mkdir CSwift && cd CSwift && swift package init
mkdir Sources/CSwift/include && rm Sources/CSwift/CSwift.swift
```

The above commands will set up the empty project template

### C Header File

Now edit the header file `Sources/CSwift/include/Swift.h`:

``` c
extern int c_add(int, int);
#define C_TEN 10
```

### C Source

Finishing the implementation of the C body `Sources/CSwift/CSwift.c`:

``` c
#include "include/CSwift.h"
int c_add(int a, int b) { return a + b ; }
```

### Module Map

Next, we will setup an umbrella file for swift: 
`Sources/CSwift/include/module.modulemap`

``` swift
module CSwift [system] {
  header "CSwift.h"
  export *
}
```

### Call C API in Swift

Now let's check if the library works by editing a test script:
`Tests/CSwiftTests/CSwiftTests.swift`

``` swift
import XCTest
@testable import CSwift
class CSwiftTests: XCTestCase {
  func testExample() {
    let three = c_add(1, 2)
    XCTAssertEqual(three, 3)
    XCTAssertEqual(C_TEN, 10)
  }
  static var allTests : [(String, (CSwiftTests) -> () throws -> Void)] {
      return [  ("testExample", testExample)  ]
  }
}
```

### Test

The final step is the easiest one - build & test:

```
$ swift build
$ swift test
```

If success, then perfect!

## Swift as Script and Call C lib dynamically

Beside the above classic static build & run, Swift also provide an interpreter to execute swift source as scripts, just like a playground in a terminal.
This project also makes an example for swift script, and even more, introduces how to call the same C api dynamically in such a script.

### Dynamic Link Library

The default linking object of Swift 4 is static, so it needs a bit modification to turn it into a dynamic one. 

To do this, edit the Package.swift file, and add a line:

``` swift
.library(
    name: "CSwift",
    type: .`dynamic`,  // <------------ Insert the dynamic type right here!
    targets: ["CSwift"]),
```

Please check a swift script `dll.swift.script`, actually it is a common swift with no difference to any other swift sources:

``` swift
// First thing first, make sure your dll path is an dynamic library in an ABSOLUTE path.
// on Mac, the suffix is ".dylib"; on Linux, it is ".so"
guard let lib = dlopen(dllpath,  RTLD_LAZY) else {
  exit(0)
}

// declare the api prototype to call
typealias AddFunc = @convention(c) (CInt, CInt) -> CInt

// look up the function in the library
guard let c_add = dlsym(lib, "c_add") else {
  dlclose(lib)
  exit(0)
}

// attache the function to the real API address
let add = unsafeBitCast(c_add, to: AddFunc.self)

// call the C method, dynamically
let x = add(1, 2)
print(x)

// release resources
dlclose(lib)
```

### Run the Swift Script

This project also provides a bash script `dll.sh` to run the swift script above.
```
# step one, build the C library
swift build

# then test what OS it is: .dylib for apple and .so for linux
if swift --version|grep apple
then
  SUFFIX=dylib
else
  SUFFIX=so
fi

# generate the full path of new library.
DLL=$PWD/.build/debug/libCSwift.$SUFFIX

# run the swift script and call the libray.
swift dll.swift.script $DLL
```

## More Info

If Xcode is preferred, then try command `swift package generate-xcodeproj` before building.
