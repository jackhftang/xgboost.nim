import xgboost

proc main() =
  let booster = newXGBooster()

  booster.loadModel("agaricus.txt.model")

  # predict
  let dtest = newXGDMatrix("agaricus.txt.test", silent=0)
  echo booster.predict(dtest)

  # predict single data
  var row: array[126, float32]
  row[1] = 1
  row[9] = 1
  row[19] = 1
  row[21] = 1
  row[24] = 1
  row[34] = 1
  row[36] = 1
  row[39] = 1
  row[42] = 1
  row[53] = 1
  row[56] = 1
  row[65] = 1
  row[69] = 1
  row[77] = 1
  row[86] = 1
  row[88] = 1
  row[92] = 1
  row[95] = 1
  row[102] = 1
  row[106] = 1
  row[117] = 1
  row[122] = 1
  echo booster.predict(@row)

when isMainModule:
  main()