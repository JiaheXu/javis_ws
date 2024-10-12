import unittest
import test.unit.test1, test.unit.test2, test.unit.test3, test.unit.test4

# //////////////////////////////////////////////////////////////////////////////

# initialize the test suite
loader = unittest.TestLoader()
suite  = unittest.TestSuite()

# add tests to the test suite
# suite.addTests(loader.loadTestsFromModule(test.unit.test1))
# suite.addTests(loader.loadTestsFromModule(test.unit.test2))
# suite.addTests(loader.loadTestsFromModule(test.unit.test3))
suite.addTests(loader.loadTestsFromModule(test.unit.test4))

# initialize a runner -- pass test suite and run it
runner = unittest.TextTestRunner( verbosity=3 )
result = runner.run(suite)
