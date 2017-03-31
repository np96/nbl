#require "Si702x.class.nut:1.0.0"
#require "LPS25H.class.nut:2.0.1"

// How long to wait between taking readings
const INTERVAL_SECONDS = 60;
// Table for collected data

hardware.i2c89.configure(CLOCK_SPEED_400_KHZ);
local tempHumidSensor = Si702x(hardware.i2c89);

local pressureSensor = LPS25H(hardware.i2c89);
pressureSensor.enable(true);

local led = hardware.pin2;
led.configure(DIGITAL_OUT, 1);


// Data structure for sensors. Each sensors array member is
// an object representing device and needed readings for it.
local sensors = [
    {
        "device": tempHumidSensor,
        "readings": ["temperature", "humidity"]
    },
    {
        "device": pressureSensor,
        "readings": ["pressure"]
    }
];

// Function factory returning callback executed each time 
// readings are taken. readingNames is the list of units
// we are interested in.
function sendReadingFactory(readingNames) {
    return function (data) {
        // Don't send anything if an error occured.
        if ("err" in data) {
            server.log("Error reading " + "\n" + reading.err);
            return;
        }
        // Make temporary object holding needed data and send
        // it to agent.
        local readingsToSend = {"values": []}
        foreach (readingName in readingNames) {
            readingsToSend.values.append(
                {
                    "key": readingName,
                    "value": data[readingName]
                });
        }
        agent.send("reading", readingsToSend);
    }
}

// Collect readings for observed devices and units.
function getReadings() {
    // Iterate through the array of sensors, 
    // collect readings for each observed unit.
    foreach (sensor in sensors) {
        local readingNames = sensor["readings"];
        sensor["device"].read(sendReadingFactory(readingNames));
    }
    imp.wakeup(INTERVAL_SECONDS, getReadings);
}


function setLed(data) {
    if (data == 0 || data == 1) {
        server.log("led set to " + data);
        led.write(data);
    }
}

// Notify the dashboard that LED state has been changed.
local ledValue = { 
    "key"  : "led",
    "value": 1 
};

agent.send("reading", {"values": [ledValue]});

agent.on("setled", setLed);
// Take a temperature reading as soon as the device starts up.
// This function schedules itself to run again in INTERVAL_SECONDS.
getReadings();
