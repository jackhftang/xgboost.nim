import ../src/xgboost
import json
import strformat

proc main() =
  var major, minor, patch: cint
  XGBoostVersion(major.addr, minor.addr, patch.addr)
  echo fmt"{major}.{minor}.{patch}"

  xgbSetGlobalConfig(%*{
    "verbosity": 3
  })
  echo xgbGetGlobalConfig()
  
  # https://raw.githubusercontent.com/dmlc/xgboost/master/demo/data/agaricus.txt.train
  let dtrain = newXGDMatrix("agaricus.txt.train", silent=0)
  # https://raw.githubusercontent.com/dmlc/xgboost/master/demo/data/agaricus.txt.test
  let dtest = newXGDMatrix("agaricus.txt.test", silent=0)
  
  let b = newXGBooster(@[dtrain, dtest])
  
  b.setParam {
    "max_depth": "2", 
    "eta": "1", 
    "objective": "binary:logistic" 
  }
  b.train(dtrain, 10)

  echo dtrain.nRow, ' ', dtrain.nCol
  echo dtest.nRow, ' ', dtest.nCol
  let res = b.predict(dtest)
  echo res.len
  echo res




when isMainModule:
  main()