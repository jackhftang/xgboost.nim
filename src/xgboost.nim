import xgboost/libxgboost
import json
import sequtils

export libxgboost

type
  XGError* = object of CatchableError
    returnCode*: int

  XGDMatrix* = ref object
    self: DMatrixHandle

  XGDevice* = ref object

  XGBooster* = ref object

# -------------------------------------------------------------
# Global Configuration

proc xgbVersion*(): tuple[major: int, minor: int, patch: int] =
  ## libxgboost version
  var major, minor, patch: cint
  XGBoostVersion(major.addr, minor.addr, patch.addr)
  return (major.int, minor.int, patch.int)

proc xgbGetLastError*(): string =
  $XGBGetLastError()

template check(x: untyped) =
  if x != 0:
    var err = newException(XGError, xgbGetLastError())
    err.returnCode = x
    raise err

proc xgbRegisterLogCallback*(callback: proc (a1: string) {.gcsafe.}) =
  check: XGBRegisterLogCallback(proc(s: cstring) {.cdecl.} = callback($s))
    
proc xgbSetGlobalConfig*(json: JsonNode) =
  let s = $json
  check: XGBSetGlobalConfig(s)

proc xgbGetGlobalConfig*(): JsonNode =
  var conf: cstring
  check: XGBGetGlobalConfig(cast[cstringArray](conf.addr))
  result = parseJson($conf)

# -------------------------------------------------------------
# XGDMatrix

proc finalize(m: XGDMatrix) =
  if not m.self.isNil:
    check: XGDMatrixFree(m.self)
    m.self = nil

proc newDMatrix*(nRow, nCol: int, data: seq[float32] = @[], missing: float32 = 0.0): XGDMatrix =
  ## create matrix content from dense matrix 
  result.new(finalize)
  var dummy: float32
  let dataPtr =
    if data.len == 0: dummy.addr
    else: cast[ptr cfloat](data[0].unsafeAddr)
  check: XGDMatrixCreateFromMat(
    dataPtr,
    nRow.uint64, nCol.uint64,
    missing, 
    result.self.addr
  )

proc nRow*(m: XGDMatrix): int =
  var tmp: uint64
  check: XGDMatrixNumRow(m.self, tmp.addr)
  result = tmp.int

proc nCol*(m: XGDMatrix): int =
  var tmp: uint64
  check: XGDMatrixNumCol(m.self, tmp.addr)
  result = tmp.int

proc slice*(handle: XGDMatrix, idx: seq[int]): XGDMatrix =
  result.new(finalize)
  var idx32 = idx.mapIt(it.cint)
  check: XGDMatrixSliceDMatrix(
    handle.self, 
    if idx32.len == 0: nil else: idx32[0].addr, 
    idx32.len.uint64, 
    result.self.addr
  )

# -------------------------------------------------------------
# XGBooster

when isMainModule:
  import strformat
  proc main() =
    var major, minor, patch: cint
    XGBoostVersion(major.addr, minor.addr, patch.addr)
    echo fmt"{major}.{minor}.{patch}"

    xgbSetGlobalConfig(%*{
      "verbosity": 3
    })
    echo xgbGetGlobalConfig()
    
    # let m = newDMatrix(@[1f32,2,3,4], 2, 2)
    let m = newDMatrix(10, 10)

    # echo m
  main()

