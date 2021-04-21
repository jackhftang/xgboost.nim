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
    self: BoosterHandle

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

proc newXGDMatrix*(nRow, nCol: int, data: seq[float32] = @[], missing: float32 = 0.0): XGDMatrix =
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

proc finalize*(b: XGBooster) =
  if not b.self.isNil:
    check: XGBoosterFree(b.self)
    b.self = nil

proc newXGBooster*(m: seq[XGDMatrix] = @[]): XGBooster =
  result.new(finalize)
  var arr = m.mapIt(it.self)
  check: XGBoosterCreate(
    if arr.len == 0: nil else: arr[0].unsafeAddr, 
    m.len.uint64, 
    result.self.addr
  )

proc setParam*(b: XGBooster, name, value: string) =
  check: XGBoosterSetParam(b.self, name, value)

proc update*(b: XGBooster, iter: int, dtrain: XGDMatrix) = 
  check: XGBoosterUpdateOneIter(b.self, iter.cint, dtrain.self)

# proc boost*(b: XGBooster, dtrain: XGDMatrix, grad) = 
proc eval*(b: XGBooster, iter: int, dmats: seq[(string, XGDMatrix)]): string = 
  var ms = dmats.mapIt(it[1].self)
  var ns = dmats.mapIt(it[0].cstring)
  result = newString(1024)
  check: XGBoosterEvalOneIter(
    b.self,
    iter.cint,
    ms[0].addr,
    ns[0].addr,
    dmats.len.uint64,
    cast[cstringArray](result.addr)
  )

proc predict*(
  b: XGBooster, 
  m: XGDMatrix, 
  json: JsonNode
): seq[float32] =
  result = newSeq[float32](m.nRow)
  # var outResult = alloc(m.nRow * sizeof(float32))
  var outResult = result[0].addr
  var jsonConf = $json
  var outShape: array[2, uint64]
  var outDim: uint64
  check: XGBoosterPredictFromDMatrix(
    b.self, m.self, 
    jsonConf[0].addr,
    cast[ptr ptr uint64](outShape.addr),
    outDim.addr,
    # cast[ptr ptr float32](outResult.addr)
    cast[ptr ptr float32](outResult.addr)
  )
  # for i in 0 ..< m.nRow:
  #   result[i] = cast[float32](cast[ByteAddress](outResult) +% i * sizeof(float32))
  # dealloc(outResult)


# proc loadModel()
# saveModel()

# getModelRaw()

# serialize
# unserialize
# saveJsonConfig
# loadJsonConfig

# dumpModel

# getAttr
# setAtrr
# getAttrNames



# slice





  

