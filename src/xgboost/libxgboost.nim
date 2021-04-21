 {.deadCodeElim: on.}
when defined(windows):
  const
    libxgboost* = "libxgboost.dll"
elif defined(macosx):
  const
    libxgboost* = "libxgboost.dylib"
else:
  const
    libxgboost* = "libxgboost.so"
type
  bst_ulong* = uint64
  DMatrixHandle* = pointer
  BoosterHandle* = pointer

proc XGBoostVersion*(major: ptr cint; minor: ptr cint; patch: ptr cint) {.cdecl,
    importc: "XGBoostVersion", dynlib: libxgboost.}
proc XGBGetLastError*(): cstring {.cdecl, importc: "XGBGetLastError",
                                dynlib: libxgboost.}
proc XGBRegisterLogCallback*(callback: proc (a1: cstring) {.cdecl.}): cint {.cdecl,
    importc: "XGBRegisterLogCallback", dynlib: libxgboost.}
proc XGBSetGlobalConfig*(json_str: cstring): cint {.cdecl,
    importc: "XGBSetGlobalConfig", dynlib: libxgboost.}
proc XGBGetGlobalConfig*(json_str: cstringArray): cint {.cdecl,
    importc: "XGBGetGlobalConfig", dynlib: libxgboost.}
proc XGDMatrixCreateFromFile*(fname: cstring; silent: cint; `out`: ptr DMatrixHandle): cint {.
    cdecl, importc: "XGDMatrixCreateFromFile", dynlib: libxgboost.}
proc XGDMatrixCreateFromCSREx*(indptr: ptr csize_t; indices: ptr cuint;
                              data: ptr cfloat; nindptr: csize_t; nelem: csize_t;
                              num_col: csize_t; `out`: ptr DMatrixHandle): cint {.
    cdecl, importc: "XGDMatrixCreateFromCSREx", dynlib: libxgboost.}
proc XGDMatrixCreateFromCSR*(indptr: cstring; indices: cstring; data: cstring;
                            ncol: bst_ulong; json_config: cstring;
                            `out`: ptr DMatrixHandle): cint {.cdecl,
    importc: "XGDMatrixCreateFromCSR", dynlib: libxgboost.}
proc XGDMatrixCreateFromCSCEx*(col_ptr: ptr csize_t; indices: ptr cuint;
                              data: ptr cfloat; nindptr: csize_t; nelem: csize_t;
                              num_row: csize_t; `out`: ptr DMatrixHandle): cint {.
    cdecl, importc: "XGDMatrixCreateFromCSCEx", dynlib: libxgboost.}
proc XGDMatrixCreateFromMat*(data: ptr cfloat; nrow: bst_ulong; ncol: bst_ulong;
                            missing: cfloat; `out`: ptr DMatrixHandle): cint {.cdecl,
    importc: "XGDMatrixCreateFromMat", dynlib: libxgboost.}
proc XGDMatrixCreateFromMat_omp*(data: ptr cfloat; nrow: bst_ulong; ncol: bst_ulong;
                                missing: cfloat; `out`: ptr DMatrixHandle;
                                nthread: cint): cint {.cdecl,
    importc: "XGDMatrixCreateFromMat_omp", dynlib: libxgboost.}
proc XGDMatrixCreateFromDT*(data: ptr pointer; feature_stypes: cstringArray;
                           nrow: bst_ulong; ncol: bst_ulong;
                           `out`: ptr DMatrixHandle; nthread: cint): cint {.cdecl,
    importc: "XGDMatrixCreateFromDT", dynlib: libxgboost.}
type
  DataIterHandle* = pointer
  DataHolderHandle* = pointer
  XGBoostBatchCSR* {.bycopy.} = object
    size*: csize_t
    columns*: csize_t
    offset*: ptr int64
    label*: ptr cfloat
    weight*: ptr cfloat
    index*: ptr cint
    value*: ptr cfloat

  XGBCallbackSetData* = proc (handle: DataHolderHandle; batch: XGBoostBatchCSR): cint {.
      cdecl.}
  XGBCallbackDataIterNext* = proc (data_handle: DataIterHandle;
                                set_function: ptr XGBCallbackSetData;
                                set_function_handle: DataHolderHandle): cint {.
      cdecl.}

proc XGDMatrixCreateFromDataIter*(data_handle: DataIterHandle;
                                 callback: ptr XGBCallbackDataIterNext;
                                 cache_info: cstring; `out`: ptr DMatrixHandle): cint {.
    cdecl, importc: "XGDMatrixCreateFromDataIter", dynlib: libxgboost.}
proc XGProxyDMatrixCreate*(`out`: ptr DMatrixHandle): cint {.cdecl,
    importc: "XGProxyDMatrixCreate", dynlib: libxgboost.}
type
  XGDMatrixCallbackNext* = proc (iter: DataIterHandle): cint {.cdecl.}
  DataIterResetCallback* = proc (handle: DataIterHandle): void {.cdecl.}

proc XGDeviceQuantileDMatrixCreateFromCallback*(iter: DataIterHandle;
    proxy: DMatrixHandle; reset: ptr DataIterResetCallback;
    next: ptr XGDMatrixCallbackNext; missing: cfloat; nthread: cint; max_bin: cint;
    `out`: ptr DMatrixHandle): cint {.cdecl, importc: "XGDeviceQuantileDMatrixCreateFromCallback",
                                  dynlib: libxgboost.}
proc XGDeviceQuantileDMatrixSetDataCudaArrayInterface*(handle: DMatrixHandle;
    c_interface_str: cstring): cint {.cdecl, importc: "XGDeviceQuantileDMatrixSetDataCudaArrayInterface",
                                   dynlib: libxgboost.}
proc XGDeviceQuantileDMatrixSetDataCudaColumnar*(handle: DMatrixHandle;
    c_interface_str: cstring): cint {.cdecl, importc: "XGDeviceQuantileDMatrixSetDataCudaColumnar",
                                   dynlib: libxgboost.}
proc XGDMatrixSliceDMatrix*(handle: DMatrixHandle; idxset: ptr cint; len: bst_ulong;
                           `out`: ptr DMatrixHandle): cint {.cdecl,
    importc: "XGDMatrixSliceDMatrix", dynlib: libxgboost.}
proc XGDMatrixSliceDMatrixEx*(handle: DMatrixHandle; idxset: ptr cint; len: bst_ulong;
                             `out`: ptr DMatrixHandle; allow_groups: cint): cint {.
    cdecl, importc: "XGDMatrixSliceDMatrixEx", dynlib: libxgboost.}
proc XGDMatrixFree*(handle: DMatrixHandle): cint {.cdecl, importc: "XGDMatrixFree",
    dynlib: libxgboost.}
proc XGDMatrixSaveBinary*(handle: DMatrixHandle; fname: cstring; silent: cint): cint {.
    cdecl, importc: "XGDMatrixSaveBinary", dynlib: libxgboost.}
proc XGDMatrixSetInfoFromInterface*(handle: DMatrixHandle; field: cstring;
                                   c_interface_str: cstring): cint {.cdecl,
    importc: "XGDMatrixSetInfoFromInterface", dynlib: libxgboost.}
proc XGDMatrixSetFloatInfo*(handle: DMatrixHandle; field: cstring; array: ptr cfloat;
                           len: bst_ulong): cint {.cdecl,
    importc: "XGDMatrixSetFloatInfo", dynlib: libxgboost.}
proc XGDMatrixSetUIntInfo*(handle: DMatrixHandle; field: cstring; array: ptr cuint;
                          len: bst_ulong): cint {.cdecl,
    importc: "XGDMatrixSetUIntInfo", dynlib: libxgboost.}
proc XGDMatrixSetStrFeatureInfo*(handle: DMatrixHandle; field: cstring;
                                features: cstringArray; size: bst_ulong): cint {.
    cdecl, importc: "XGDMatrixSetStrFeatureInfo", dynlib: libxgboost.}
proc XGDMatrixGetStrFeatureInfo*(handle: DMatrixHandle; field: cstring;
                                size: ptr bst_ulong; out_features: ptr cstringArray): cint {.
    cdecl, importc: "XGDMatrixGetStrFeatureInfo", dynlib: libxgboost.}
proc XGDMatrixSetDenseInfo*(handle: DMatrixHandle; field: cstring; data: pointer;
                           size: bst_ulong; `type`: cint): cint {.cdecl,
    importc: "XGDMatrixSetDenseInfo", dynlib: libxgboost.}
proc XGDMatrixSetGroup*(handle: DMatrixHandle; group: ptr cuint; len: bst_ulong): cint {.
    cdecl, importc: "XGDMatrixSetGroup", dynlib: libxgboost.}
proc XGDMatrixGetFloatInfo*(handle: DMatrixHandle; field: cstring;
                           out_len: ptr bst_ulong; out_dptr: ptr ptr cfloat): cint {.
    cdecl, importc: "XGDMatrixGetFloatInfo", dynlib: libxgboost.}
proc XGDMatrixGetUIntInfo*(handle: DMatrixHandle; field: cstring;
                          out_len: ptr bst_ulong; out_dptr: ptr ptr cuint): cint {.
    cdecl, importc: "XGDMatrixGetUIntInfo", dynlib: libxgboost.}
proc XGDMatrixNumRow*(handle: DMatrixHandle; `out`: ptr bst_ulong): cint {.cdecl,
    importc: "XGDMatrixNumRow", dynlib: libxgboost.}
proc XGDMatrixNumCol*(handle: DMatrixHandle; `out`: ptr bst_ulong): cint {.cdecl,
    importc: "XGDMatrixNumCol", dynlib: libxgboost.}
proc XGBoosterCreate*(dmats: ptr DMatrixHandle; len: bst_ulong;
                     `out`: ptr BoosterHandle): cint {.cdecl,
    importc: "XGBoosterCreate", dynlib: libxgboost.}
proc XGBoosterFree*(handle: BoosterHandle): cint {.cdecl, importc: "XGBoosterFree",
    dynlib: libxgboost.}
proc XGBoosterSlice*(handle: BoosterHandle; begin_layer: cint; end_layer: cint;
                    step: cint; `out`: ptr BoosterHandle): cint {.cdecl,
    importc: "XGBoosterSlice", dynlib: libxgboost.}
proc XGBoosterBoostedRounds*(handle: BoosterHandle; `out`: ptr cint): cint {.cdecl,
    importc: "XGBoosterBoostedRounds", dynlib: libxgboost.}
proc XGBoosterSetParam*(handle: BoosterHandle; name: cstring; value: cstring): cint {.
    cdecl, importc: "XGBoosterSetParam", dynlib: libxgboost.}
proc XGBoosterGetNumFeature*(handle: BoosterHandle; `out`: ptr bst_ulong): cint {.
    cdecl, importc: "XGBoosterGetNumFeature", dynlib: libxgboost.}
proc XGBoosterUpdateOneIter*(handle: BoosterHandle; iter: cint; dtrain: DMatrixHandle): cint {.
    cdecl, importc: "XGBoosterUpdateOneIter", dynlib: libxgboost.}
proc XGBoosterBoostOneIter*(handle: BoosterHandle; dtrain: DMatrixHandle;
                           grad: ptr cfloat; hess: ptr cfloat; len: bst_ulong): cint {.
    cdecl, importc: "XGBoosterBoostOneIter", dynlib: libxgboost.}
proc XGBoosterEvalOneIter*(handle: BoosterHandle; iter: cint;
                          dmats: ptr DMatrixHandle; evnames: ptr cstring;
                          len: bst_ulong; out_result: cstringArray): cint {.cdecl,
    importc: "XGBoosterEvalOneIter", dynlib: libxgboost.}
proc XGBoosterPredict*(handle: BoosterHandle; dmat: DMatrixHandle; option_mask: cint;
                      ntree_limit: cuint; training: cint; out_len: ptr bst_ulong;
                      out_result: ptr ptr cfloat): cint {.cdecl,
    importc: "XGBoosterPredict", dynlib: libxgboost.}
proc XGBoosterPredictFromDMatrix*(handle: BoosterHandle; dmat: DMatrixHandle;
                                 c_json_config: cstring;
                                 out_shape: ptr ptr bst_ulong;
                                 out_dim: ptr bst_ulong; out_result: ptr ptr cfloat): cint {.
    cdecl, importc: "XGBoosterPredictFromDMatrix", dynlib: libxgboost.}
proc XGBoosterPredictFromDense*(handle: BoosterHandle; values: cstring;
                               c_json_config: cstring; m: DMatrixHandle;
                               out_shape: ptr ptr bst_ulong; out_dim: ptr bst_ulong;
                               out_result: ptr ptr cfloat): cint {.cdecl,
    importc: "XGBoosterPredictFromDense", dynlib: libxgboost.}
proc XGBoosterPredictFromCSR*(handle: BoosterHandle; indptr: cstring;
                             indices: cstring; values: cstring; ncol: bst_ulong;
                             c_json_config: cstring; m: DMatrixHandle;
                             out_shape: ptr ptr bst_ulong; out_dim: ptr bst_ulong;
                             out_result: ptr ptr cfloat): cint {.cdecl,
    importc: "XGBoosterPredictFromCSR", dynlib: libxgboost.}
proc XGBoosterPredictFromCudaArray*(handle: BoosterHandle; values: cstring;
                                   c_json_config: cstring; m: DMatrixHandle;
                                   out_shape: ptr ptr bst_ulong;
                                   out_dim: ptr bst_ulong;
                                   out_result: ptr ptr cfloat): cint {.cdecl,
    importc: "XGBoosterPredictFromCudaArray", dynlib: libxgboost.}
proc XGBoosterPredictFromCudaColumnar*(handle: BoosterHandle; values: cstring;
                                      c_json_config: cstring; m: DMatrixHandle;
                                      out_shape: ptr ptr bst_ulong;
                                      out_dim: ptr bst_ulong;
                                      out_result: ptr ptr cfloat): cint {.cdecl,
    importc: "XGBoosterPredictFromCudaColumnar", dynlib: libxgboost.}
proc XGBoosterLoadModel*(handle: BoosterHandle; fname: cstring): cint {.cdecl,
    importc: "XGBoosterLoadModel", dynlib: libxgboost.}
proc XGBoosterSaveModel*(handle: BoosterHandle; fname: cstring): cint {.cdecl,
    importc: "XGBoosterSaveModel", dynlib: libxgboost.}
proc XGBoosterLoadModelFromBuffer*(handle: BoosterHandle; buf: pointer;
                                  len: bst_ulong): cint {.cdecl,
    importc: "XGBoosterLoadModelFromBuffer", dynlib: libxgboost.}
proc XGBoosterGetModelRaw*(handle: BoosterHandle; out_len: ptr bst_ulong;
                          out_dptr: cstringArray): cint {.cdecl,
    importc: "XGBoosterGetModelRaw", dynlib: libxgboost.}
proc XGBoosterSerializeToBuffer*(handle: BoosterHandle; out_len: ptr bst_ulong;
                                out_dptr: cstringArray): cint {.cdecl,
    importc: "XGBoosterSerializeToBuffer", dynlib: libxgboost.}
proc XGBoosterUnserializeFromBuffer*(handle: BoosterHandle; buf: pointer;
                                    len: bst_ulong): cint {.cdecl,
    importc: "XGBoosterUnserializeFromBuffer", dynlib: libxgboost.}
proc XGBoosterLoadRabitCheckpoint*(handle: BoosterHandle; version: ptr cint): cint {.
    cdecl, importc: "XGBoosterLoadRabitCheckpoint", dynlib: libxgboost.}
proc XGBoosterSaveRabitCheckpoint*(handle: BoosterHandle): cint {.cdecl,
    importc: "XGBoosterSaveRabitCheckpoint", dynlib: libxgboost.}
proc XGBoosterSaveJsonConfig*(handle: BoosterHandle; out_len: ptr bst_ulong;
                             out_str: cstringArray): cint {.cdecl,
    importc: "XGBoosterSaveJsonConfig", dynlib: libxgboost.}
proc XGBoosterLoadJsonConfig*(handle: BoosterHandle; json_parameters: cstring): cint {.
    cdecl, importc: "XGBoosterLoadJsonConfig", dynlib: libxgboost.}
proc XGBoosterDumpModel*(handle: BoosterHandle; fmap: cstring; with_stats: cint;
                        out_len: ptr bst_ulong; out_dump_array: ptr cstringArray): cint {.
    cdecl, importc: "XGBoosterDumpModel", dynlib: libxgboost.}
proc XGBoosterDumpModelEx*(handle: BoosterHandle; fmap: cstring; with_stats: cint;
                          format: cstring; out_len: ptr bst_ulong;
                          out_dump_array: ptr cstringArray): cint {.cdecl,
    importc: "XGBoosterDumpModelEx", dynlib: libxgboost.}
proc XGBoosterDumpModelWithFeatures*(handle: BoosterHandle; fnum: cint;
                                    fname: cstringArray; ftype: cstringArray;
                                    with_stats: cint; out_len: ptr bst_ulong;
                                    out_models: ptr cstringArray): cint {.cdecl,
    importc: "XGBoosterDumpModelWithFeatures", dynlib: libxgboost.}
proc XGBoosterDumpModelExWithFeatures*(handle: BoosterHandle; fnum: cint;
                                      fname: cstringArray; ftype: cstringArray;
                                      with_stats: cint; format: cstring;
                                      out_len: ptr bst_ulong;
                                      out_models: ptr cstringArray): cint {.cdecl,
    importc: "XGBoosterDumpModelExWithFeatures", dynlib: libxgboost.}
proc XGBoosterGetAttr*(handle: BoosterHandle; key: cstring; `out`: cstringArray;
                      success: ptr cint): cint {.cdecl, importc: "XGBoosterGetAttr",
    dynlib: libxgboost.}
proc XGBoosterSetAttr*(handle: BoosterHandle; key: cstring; value: cstring): cint {.
    cdecl, importc: "XGBoosterSetAttr", dynlib: libxgboost.}
proc XGBoosterGetAttrNames*(handle: BoosterHandle; out_len: ptr bst_ulong;
                           `out`: ptr cstringArray): cint {.cdecl,
    importc: "XGBoosterGetAttrNames", dynlib: libxgboost.}
proc XGBoosterSetStrFeatureInfo*(handle: BoosterHandle; field: cstring;
                                features: cstringArray; size: bst_ulong): cint {.
    cdecl, importc: "XGBoosterSetStrFeatureInfo", dynlib: libxgboost.}
proc XGBoosterGetStrFeatureInfo*(handle: BoosterHandle; field: cstring;
                                len: ptr bst_ulong; out_features: ptr cstringArray): cint {.
    cdecl, importc: "XGBoosterGetStrFeatureInfo", dynlib: libxgboost.}