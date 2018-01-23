# Swift 调用 C 语言自建函数库 及 Swift 脚本和动态链接库的使用方法 [English](README.md)

Rockford Wei，2017-01-17

本程序示范了如何用Swift调用自定义C语言模块的方法。您可以直接下载本程序，或者按照以下教程逐步完成。
此外，示范程序还展示了如何使用 Swift 作为脚本运行，并且在脚本中调用C语言的动态链接库，使得服务器端Swift 开发实现热补丁。

## 简介

示范程序中有一个C语言的源程序CSwift.c和一个头文件CSwift.h，我们的目标是构造一个CSwift的函数库，能够让swift源程序执行CSwift程序中的函数。

## 快速上手

本程序需要Swift 3.0以上版本。

### 下载、编译和测试

```
$ git clone https://github.com/RockfordWei/CSwift.git
$ cd CSwift
$ swift build
$ swift test
```
源程序采用C语言写成，测试程序则是Swift语言编写。因此如果通过测试，则恭喜您，已经成功实现了Swift语言调用C语言的整个过程。

## 详细步骤

您可以完全不依赖所有上述内容，而一步一步从零开始制作C函数库和调用C库的Swift代码：

### 构造空白的函数库

仍然假定函数库名称为CSwift。首先找一个空白目录，然后执行：

```
$ mkdir CSwift
$ cd CSwift
$ swift package init --type=system-module
$ mkdir CSwift
$ cd CSwift
$ swift package init
$ mv Tests ..
$ mkdir include
$ mv ../module.modulemap include/
$ rm Package.swift
$ rm -rf Sources
$ echo > CSwift.c
$ echo > include/CSwift.h
$ cd ..
```

细心的读者会发现，上面的bash 命令行在CSwift 文件夹下面建立了第二个CSwift文件夹，但是使用了不同的`swift package`了命令。第一个命令是“创建swift空白项目，而且项目类型是系统模块”；而第二个命令是“创建swift 空白项目，项目类型是函数库”。这种做法主要是为了能够在同一个项目中用Swift去测试C语言的模块。其次，在第二个CSwift 子目录下，还建立了一个include 文件夹，并分别建立了两个空白源程序文件 CSwift.c 和 CSwift.h

### Module Map

下一步是修理一下目标的模块映射表。请把module.modulemap修改为如下程序：

``` swift
module CSwift [system] {
  header "CSwift.h"
  link "CSwift"
  export *
}
```

### C模块编程

好了，现在请编辑刚才在第二个CSwift文件夹下面的建立两个C语言文件：CSwift.c和CSwift.h，内容如下：

#### CSwift/CSwift/include/CSwift.h

``` c
extern int c_add(int, int);
#define C_TEN 10
```

#### CSwift/CSwift/CSwift.c

``` c
#include "include/CSwift.h"
int c_add(int a, int b) { return a + b ; }
```

到此为止，C语言函数库就应该准备好了。

### Swift 程序调用

请修改Tests/CSwiftTests/CSwiftTests.swift文件，内容如下：

``` swift

import XCTest
@testable import CSwift

class CSwiftTests: XCTestCase {
    func testExample() {
        // 测试调用 C 函数
        let three = c_add(1, 2)
        XCTAssertEqual(three, 3)
        // 测试调用 C 语言的符号
        XCTAssertEqual(C_TEN, 10)
    }


    static var allTests : [(String, (CSwiftTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}

```

### 测试

最后一步最简单，直接执行：

```
$ swift build
$ swift test
```

如果没有问题，那就一切OK了！

## Swift 脚本解释器的使用以及动态链接库的调用

除了以上正文之外，Swift 还提供了直接以解释器执行 Swift脚本的方法，相当于在linux或mac命令行直接使用playground。
本文顺便利用这个脚本，同时说明一下动态链接库的使用方法。

### 动态链接库

本项目附带了一个特殊脚本dll.swift.script，内容为一个普通Swift 源程序：

``` swift
// 首先dllpath 一定是编译完成的C语言动态链接库，在mac上是.dylib文件，在linux上是.so文件
// 请注意dllpath 一定是绝对路径
guard let lib = dlopen(dllpath,  RTLD_LAZY) else {
  exit(0)
}

// 然后声明需要引用的函数类型
typealias AddFunc = @convention(c) (CInt, CInt) -> CInt

// 用dlsym方法真正获取目标函数的地址
guard let c_add = dlsym(lib, "c_add") else {
  dlclose(lib)
  exit(0)
}

// 将动态函数库函数地址绑定到刚才声明的函数类型上
let add = unsafeBitCast(c_add, to: AddFunc.self)

// 调用动态链接库
let x = add(1, 2)
print(x)

// 释放资源
dlclose(lib)
```

### 用Swift脚本调用动态链接库

附件中还包括了另外一个bash脚本dll.sh，供运行上述脚本并调用动态链接库
```
# 首先编译一下C函数库
swift build

# 然后判断操作系统类型，如果是苹果则使用.dylib，如果是Linux就用.so
if swift --version|grep apple
then
  SUFFIX=dylib
else
  SUFFIX=so
fi

# 合成动态函数库名称
DLL=$PWD/.build/debug/libCSwift.$SUFFIX

# 用swift 解释器调用脚本，并执行动态链接库调用
swift dll.swift.script $DLL
```

## 其他

如果您在使用Xcode，则需要使用`swift package generate-xcodeproj`。
