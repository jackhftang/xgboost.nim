import xgboost/libxgboost
import json
import sequtils
import strformat

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

proc newXGDMatrix*(fname: string, silent: int = 1): XGDMatrix =
  result.new(finalize)
  check: XGDMatrixCreateFromFile(fname, silent.cint, result.self.addr)

proc newXGDMatrix*(data: seq[float32], nRow, nCol: int, missing: float32 = NaN.float32): XGDMatrix =
  if data.len != nRow * nCol:
    raise newException(XGError, fmt"invalid length of data data.len={data.len} nRow={nRow} nCol={nCol}")

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

proc newXGDMatrix*(data: seq[float32], nRow: int, missing: float32 = NaN.float32): XGDMatrix =
  let nCol = data.len div nRow
  if nCol * nRow != data.len:
    raise newException(XGError, fmt"invalid length of data data.len={data.len} nRow={nRow}")
  result = newXGDMatrix(data, nRow, nCol, missing)

proc newXGDMatrix*[N: static int](data: seq[array[N, float32]], missing: float32 = NaN.float32): XGDMatrix =
  let nRow = N
  let nCol = data.len div nRow
  if nCol * nRow != data.len:
    raise newException(XGError, fmt"invalid length of data data.len={data.len} nRow={nRow}")
  result = newXGDMatrix(data, nRow, nCol, missing)

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

proc setParam*(b: XGBooster, pairs: openArray[(string, string)]) =
  for pair in pairs:
    b.setParam(pair[0], pair[1])

proc update*(b: XGBooster, iter: int, dtrain: XGDMatrix) = 
  check: XGBoosterUpdateOneIter(b.self, iter.cint, dtrain.self)

proc eval*(b: XGBooster, iter: int, dmats: openArray[(string, XGDMatrix)]): string = 
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

proc train*(b: XGBooster, dtrain: XGDMatrix, nRound: int) = 
  for i in 1..nRound:
    b.update(i, dtrain)

proc predict*(
  b: XGBooster, 
  m: XGDMatrix, 
  # json: JsonNode = newJObject()
): seq[float32] =
  result = newSeq[float32](m.nRow)
  # var outResult = alloc(m.nRow * sizeof(float32))
  var jsonConf = $ %*{
    "type": 0,
    "training": false,
    "iteration_begin": 0,
    "iteration_end": 0,
    "strict_shape": true,
  }
  var outResult = result[0].addr
  var outShape: array[4, uint64]
  var outDim: uint64
  echo "outShape=", outShape
  check: XGBoosterPredictFromDMatrix(
    b.self, m.self, 
    jsonConf[0].addr,
    cast[ptr ptr uint64](outShape.addr),
    outDim.addr,
    # cast[ptr ptr float32](outResult.addr)
    cast[ptr ptr float32](outResult.addr)
  )
  echo "outShape=", outShape
  echo "outDim=", outDim
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





  

