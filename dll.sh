swift build
if swift --version|grep apple
then
  SUFFIX=dylib
else
  SUFFIX=so
fi
DLL=$PWD/.build/debug/libCSwift.$SUFFIX
swift dll.swift.script $DLL
