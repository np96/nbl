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

// Iterate readings and send each value
function sendReading(data) {
    if ("err" in data) {
        server.error("Error reading" + "\n" + data.err);
        return;
    }
    foreach(readingKey, readingValue in data) {
        agent.send("reading", {"key" : readingKey
                               "value": readingValue
                              });
    }
}

// Collect readings for observed devices and units.
function getReadings() {
    tempHumidSensor.read(sendReading);
    pressureSensor.read(sendReading);
    imp.wakeup(INTERVAL_SECONDS, getReadings);
}

function setLed(data) {
    if (data == 0 || data == 1) {
        server.log("led set to " + data);
        led.write(data);
    } else {
        server.error("Tried to set incorrect led value: " + data);
    }
}

// Notify the dashboard that LED state has been changed.
local ledValue = { 
    "key"  : "led",
    "value": 1 
};

agent.send("led", ledValue);
agent.on("setled", setLed);
// Take a temperature reading as soon as the device starts up.
// This function schedules itself to run again in INTERVAL_SECONDS.
getReadings();
