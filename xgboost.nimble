# Package

version       = "0.1.0"
author        = "Jack Tang"
description   = "Nim wrapper for libxgboost"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.4.0"

task clone_xgboost, "clone xgboost":
  exec "git clone --depth 1 --branch v1.4.1 https://github.com/dmlc/xgboost.git xgboost"
  withDir "xgboost":
    exec "git submodule init"
    exec "git submodule update"

task build_xgboost, "build xgboost":
  exec "mkdir -p xgboost/build"
  withDir "xgboost/build":
    exec "cmake .."
    exec "make"