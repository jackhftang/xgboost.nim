import xgboost

proc main() =
  let booster = newXGBooster()

  booster.loadModel("agaricus.txt.model")

  let dtest = newXGDMatrix("agaricus.txt.test", silent=0)
  echo booster.predict(dtest)

when isMainModule:
  main()