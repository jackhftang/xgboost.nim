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

proc updateNimbleVersion(ver: string) =
  let fname = currentSourcePath()
  let txt = readFile(fname)
  var lines = txt.split("\n")
  for i, line in lines:
    if line.startsWith("version"): 
      let s = line.find('"')
      let e = line.find('"', s+1)
      lines[i] = line[0..s] & ver & line[e..<line.len]
      break
  writeFile(fname, lines.join("\n"))

task version, "update version":
  # last params as version
  let ver = paramStr( paramCount() )
  if ver == "version": 
    # print current version
    echo version
  else:
    withDir thisDir(): 
      updateNimbleVersion(ver)

task gendoc, "generate docs":
  exec "nim doc --out:docs --project src/xgboost.nim"

task release_patch, "release with patch increment":
  exec "release-it --ci -i patch"

task release_minor, "releaes with minor increment":
  exec "release-it --ci -i minor"

task release_major, "release with major increment":
  exec "release-it --ci -i major"