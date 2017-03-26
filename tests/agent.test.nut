
local ledVal = -1;

class CaseAgent extends ImpTestCase {

  function setUp() {
    server.log("Setting up");
  }

  function getThingIO(value) {
    return http.jsondecode(convertToThingIO(value));
  }

  function assertRepresentationsEqual(converted, expected) {
    this.assertDeepEqual(convertFromThingIO(converted["values"]), expected);
  }

  function test_convert() {
    local tests = [{"myKey1": "1", "myKey2" : "2", "myKey3" : "3"}, {"myKey1": [1,2,3], "myKey2": 1562, "myKey3": {"myKey1": {"myKey1": "1", "myKey2" : "2", "myKey3" : "3"}}}];
    
    foreach (testCase in tests) {
      local converted = getThingIO(testCase);
      this.assertRepresentationsEqual(converted, testCase);
    }
  }

  function test_led() {
    local values = [1,1,1,1,1,1, 1.3, 0, 1, 1.2, 1.3, 1, 2.5, 2, 5, 6 ,7, 2.9, 8, 16, -125, 5, 6, 7, 2];
    foreach (value in values) { 
      device.send("setled", value);
    }
    local i = 0;
    local prom =
     Promise(function (resolve, reject) {
          imp.wakeup(15, function() {
            if (ledVal == 1) {
              resolve("OK 1");
            } else {
              reject("ledVal != 1: " + ledVal);
            }
          }.bindenv(this));
    }.bindenv(this));
    prom.then(function (res) {
    server.log(res);
    this.assertTrue(true);
  }.bindenv(this)).fail(function (res) {
    server.log(res);
    this.assertTrue(false);
  }.bindenv(this));
  return prom;
  }
}

device.on("led", function(data) {
      server.log("blah");
      ledVal = data;
      server.log(ledVal);
    });

testRunner <- ImpUnitRunner();
testRunner.timeout = 30;
testRunner.readableOutput = true;
testRunner.stopOnFailure = true;
testRunner.run();