local AGENT_URL = "https://agent.electricimp.com/r5_UGUxVt2Dh?setled=";
local JSON_HEADER = {"Content-Type": "application/json"};
class CaseAgent extends ImpTestCase {

  // Wrap sendasync function in Promise, send
  // request to agent and test if returned status 
  // code is equal to expectedCode.
  static function promisedSendAsync(request, expectedCode) {
    return Promise(function (resolve, reject) {
        request.sendasync(function (response) {
            if (response.statuscode == expectedCode) {
              return resolve("TEST OK. " + expectedCode + "==" + response.statuscode);
            } 
            return reject("TEST FAILED. " + expectedCode + "!=" + response.statuscode);
        }.bindenv(this));
    }.bindenv(this)); 
  }


  // Make http request and log the result.
  function ledTestRun(value, expectedCode) {
    local req = http.post(AGENT_URL + value, JSON_HEADER, "");
    return promisedSendAsync(req, expectedCode)
     .finally(function (msg) {
        server.log(msg);
     }.bindenv(this));
    }

  // Check if can't set non-numeric value
  function test_incorrectLed() {
    ledTestRun("aab", 500);
    ledTestRun("", 500);
  }

  // Must return OK
  function test_correctLed() {
    ledTestRun("1", 200);
    ledTestRun("0", 200);
  }
}