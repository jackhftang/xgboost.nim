import unittest
import xgboost
import options

suite "xgbooster":

  test "attr":
    let booster = newXGBooster()
    booster.setAttr("hello", "world")
    check: booster.getAttr("hello") == some("world")
    check: booster.getAttrNames() == @["hello"]