# xgboost.nim 

Nim binding of [xgboost 1.4.x](https://github.com/dmlc/xgboost/tree/v1.4.1)

## Usage

```nim
import xgboost

proc main() =
  let dtrain = newXGDMatrix("agaricus.txt.train", silent=0)
  let dtest = newXGDMatrix("agaricus.txt.test", silent=0)
  
  # train
  let booster = train({
    "max_depth": "2", 
    "eta": "1", 
    "objective": "binary:logistic" 
  }, dtrain)

  # predict
  let res = booster.predict(dtest)
  echo res

  # save
  booster.saveModel("agaricus.txt.model")

when isMainModule:
  main()
```

## API

see [here](https://jackhftang.github.io/xgboost.nim/)