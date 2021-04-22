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

proc newXGBooster*(toCaches: seq[XGDMatrix] = @[]): XGBooster =
  result.new(finalize)
  var arr = toCaches.mapIt(it.self)
  check: XGBoosterCreate(
    if arr.len == 0: nil else: arr[0].unsafeAddr, 
    toCaches.len.uint64, 
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
  var outResult: ptr char
  check: XGBoosterEvalOneIter(
    b.self,
    iter.cint,
    ms[0].addr,
    ns[0].addr,
    dmats.len.uint64,
    cast[cstringArray](outResult.addr)
  )  

  # copy output message, at most 4k bytes just in case no '\0'
  var i: int
  while i < 4 * 1024:
    let c = cast[ptr char](cast[ByteAddress](outResult) +% i.int * sizeof(char))[]
    if c == '\0': break
    result.add c
    i.inc

proc train*(
  params: openArray[(string, string)], 
  dtrain: XGDMatrix, 
  num_boost_round: int = 10,
  evals: openArray[(string, XGDMatrix)] = [],
): XGBooster = 
  var toCaches = @[dtrain]
  for eval in evals:
    toCaches.add eval[1]

  result = newXGBooster(toCaches)
  for i in 1..num_boost_round:
    result.update(i, dtrain)
    if evals.len > 0: 
      echo result.eval(i, evals)

proc predict*(
  b: XGBooster, 
  m: XGDMatrix
): seq[float32] =
  var jsonConf = $ %*{
    "type": 0,
    "training": false,
    "iteration_begin": 0,
    "iteration_end": 0,
    "strict_shape": true,
  }

  var outShapePtr: ptr uint64
  var outDim: uint64
  var outResultPtr: ptr float32
  check: XGBoosterPredictFromDMatrix(
    b.self, m.self, 
    jsonConf[0].addr,
    outShapePtr.addr,
    outDim.addr,
    outResultPtr.addr
  )
  assert outDim == 2

  # find out outShape
  # var outShape: seq[uint64]
  var size: uint64 = 1
  for i in 0 ..< outDim:
      let n = cast[ptr uint64](cast[ByteAddress](outShapePtr) +% i.int * sizeof(uint64))[]
      # outShape.add n
      size *= n
  # assert outShape[1] == 1

  # copy result
  result = newSeq[float32](size)
  for i in 0 ..< size:
    result[i] = cast[ptr float32](cast[ByteAddress](outResultPtr) +% i.int * sizeof(float32))[]

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





  

