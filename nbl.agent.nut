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


// Converts squirrel table to thething.io json message format.
function convertToThingIO(body) {
    local res = {"values" : []};
    foreach (key, value in body) {
        res.values.append({"key": key,
                           "value": value
        });
    }
    return http.jsonencode(res);
}

function convertFromThingIO(body) {
    local res = {}
    foreach (kvp in body) {
        res[kvp["key"]] <- kvp["value"];
    }
    return res;
}

// Post reading from the device to thething.io.
function postReading(reading) {
    local body = convertToThingIO(reading);
    server.log("sending readings: " + body);
    local req = http.post(API_URL, THE_THINGS_HEADER, body);
    req.sendasync(processResponse);
}


// Sends initial LED state to thething.io and subscribes to the channel.
function sendLed(number) {
    local req = http.post(API_URL, THE_THINGS_HEADER, convertToThingIO({"led": number}));
    req.sendasync(processResponse);
}

device.on("reading", postReading);
device.on("led", sendLed);
