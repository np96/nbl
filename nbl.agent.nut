#line 1 "nbl.agent.nut"
// Sensors data key
const READING_KEY = "YOUR_KEY";
// Led channel key
const LED_KEY = "YOUR_LED_KEY";
local API_URL = "https://api.thethings.io/v2/things/" + READING_KEY;
local LED_URL =
"https://api.thethings.io/v2/things/" + LED_KEY;
local LED_SUB_URL =
"https://api.thethings.io/v2/things/" + LED_KEY + "?keepAlive=60000";

const LOOP_TIME = 6000;

THE_THINGS_HEADER <- {"Content-Type": "application/json"}



// Log the response
function processResponse(response) {
     server.log("Code: " + response.statuscode + ". Message: " + response.body);
}


// Emitted each time LED channel sends us chunk reply.
function processLedResponse(response) {
    // Log raw response string
    server.log("LED raw: " + response);
    // Streaming response is raw string so we need to 
    // convert it to Squrrel data structure first
    response = http.jsondecode(response);
    // Initial response chunk is success/failure message
    // e.g. {"status":"success","message":"streaming"}
    if ("status" in response) {
        server.log("LED status: " + response.status);
    }
    // Thingio's response is array, but we observe single
    // value which might only be changed by user via switch
    // e.g. [{"key":"led","value":"0"}]
    else if (typeof response == "array" 
            && typeof response[0] == "table"
            && response[0].rawin("value")) {
        server.log("setting LED: " + response[0].value);
        device.send("setled", response[0].value.tointeger());
    }
}



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

// Led loop: subscribes to LED updates channel each 100 minutes.
function loopLed() {
    local req = http.get(LED_SUB_URL, THE_THINGS_HEADER);
    req.sendasync(processResponse, processLedResponse, NO_TIMEOUT);
    imp.wakeup(LOOP_TIME, function () {
        req.cancel();
        loopLed();
    });
    
}

function subscribeLed(data) {
    processResponse(data);
    loopLed();
}

// Sends initial LED state to thething.io and subscribes to the channel.
function sendLedAndSubscribe(number) {
    local req = http.post(LED_URL, THE_THINGS_HEADER, convertToThingIO({"led": number}));
    
    // Subscribe when the initial LED state is sent to the server.
    req.sendasync(subscribeLed);
}

device.on("led", sendLedAndSubscribe);
device.on("reading", postReading);
