export LIB_BUILD=.build/debug
cd Sources
clang -c CSwift.c
cd ..
mv Sources/CSwift.o $LIB_BUILD
ar -r $LIB_BUILD/libCSwift.a $LIB_BUILD/CSwift.o
export LIB_BUILD=
