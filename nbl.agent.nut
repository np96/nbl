// Sensors data key
const READING_KEY = "YOUR_KEY";
// Led channel key
local API_URL = "https://api.thethings.io/v2/things/" + READING_KEY;

local THE_THINGS_HEADER = {"Content-Type": "application/json"}

// Log the response
function processResponse(response) {
     server.log("Code: " + response.statuscode + ". Message: " + response.body);
}


// Handles led setting request
function ledHandler(request, response) {
    server.log("Handling request");
    try {
        if ("setled" in request.query) {
            device.send("setled", request.query["setled"].tointeger());
        }
        response.send(200, "OK");
    } catch (ex) {
        response.send(500, "Internal error: " + ex);
    }
}

http.onrequest(ledHandler);

// Post reading from the device to thething.io.
function postReading(reading) {
    reading = http.jsonencode({"values" : [reading]});
    server.log("sending readings: " + reading);
    local req = http.post(API_URL, THE_THINGS_HEADER, reading);
    req.sendasync(processResponse);
}

device.on("reading", postReading);
