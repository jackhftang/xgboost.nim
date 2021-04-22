# xgboost.nim 

Nim wrapper for libxgboost 1.4.x

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

when isMainModule:
  main()
```

