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
  
  # let m = newDMatrix(@[1f32,2,3,4], 2, 2)
  let m = newXGDMatrix(10, 10)
  let b = newXGBooster()

when isMainModule:
  main()