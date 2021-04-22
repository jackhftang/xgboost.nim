# xgboost.nim 

Nim binding of [xgboost 1.4.x](https://github.com/dmlc/xgboost/tree/v1.4.1)

## Installation

This binding depends on the shared library of xgboost. You should be able to build it with the following commands.

```sh
nimble clone_xgboost
nimble build_xgboost
```

The resulting shared library should be located in `./xgboost/lib/`.
If you encouter issues during build, consult the installation guide of xgboost.

## Usage

```nim
import xgboost

proc main() =
  # global config
  xgbSetGlobalConfig(%*{
    "verbosity": 3
  })

  # https://github.com/dmlc/xgboost/tree/master/demo/data
  let dtrain = newXGDMatrix("agaricus.txt.train")
  let dtest = newXGDMatrix("agaricus.txt.test")
  
  # train
  let booster = train({
    "max_depth": "2", 
    "eta": "1", 
    "objective": "binary:logistic" 
  }, dtrain)

  # predict
  let res = booster.predict(dtest)
  echo res

  # save model
  booster.saveModel("agaricus.txt.model")

when isMainModule:
  main()
```

## API

see [here](https://jackhftang.github.io/xgboost.nim/)