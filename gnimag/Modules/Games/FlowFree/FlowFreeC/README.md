# FlowFreeC

`FlowFreeC` is an ObjC-framework that supplements `FlowFree` with C code.

This is required for `swift build` (i.e. `make`), because `swift build` does not support targets with mixed language source files. Therefore, C files cannot be directly in the `FlowFree` target, but have to be outsourced to this target.
