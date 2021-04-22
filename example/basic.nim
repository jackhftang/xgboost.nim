import xgboost
import json
import options
import strformat

proc main() =
  # version
  var (major, minor, patch) = xgbVersion()
  echo "version=", fmt"{major}.{minor}.{patch}"

  # global config
  xgbSetGlobalConfig(%*{
    "verbosity": 3
  })
  echo "globalConfig=", xgbGetGlobalConfig()
  
  # https://github.com/dmlc/xgboost/tree/master/demo/data
  let dtrain = newXGDMatrix("agaricus.txt.train", silent=0)
  let dtest = newXGDMatrix("agaricus.txt.test", silent=0)
  echo "dtrain.shape=", dtrain.nRow, 'x', dtrain.nCol
  echo "dtest.shape=", dtest.nRow, 'x', dtest.nCol

  # train
  let params = {
    "max_depth": "2", 
    "eta": "1", 
    "objective": "binary:logistic" 
  }
  let nRound = 100
  let booster = train(params, dtrain, nRound, evals={
    "train": dtrain,
    "test": dtest,
  })

  # predict
  echo booster.predict(dtest)

  # save model
  booster.saveModel("agaricus.txt.model")

when isMainModule:
  main()