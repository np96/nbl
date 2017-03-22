#require "Si702x.class.nut:1.0.0"
#require "LPS25H.class.nut:2.0.1"

// How long to wait between taking readings
const INTERVAL_SECONDS = 60;

// Table for collected data
data <- {
    "temperature": null,
    "pressure": null,
    "humidity": null,
}

hardware.i2c89.configure(CLOCK_SPEED_400_KHZ);
local tempHumidSensor = Si702x(hardware.i2c89);

local pressureSensor = LPS25H(hardware.i2c89);
pressureSensor.enable(true);

local led = hardware.pin2;
led.configure(DIGITAL_OUT, 0);


// Data structure for sensors. Each sensors array member 
// matches needReadings array member. Each needReadings array member
// is array of observed units. For example, for tempHumidSensor
// we collect temperature and humidity. 
local needReadings = [["temperature", "humidity"], ["pressure"]]; 
local sensors = [tempHumidSensor, pressureSensor];
// Assert that arrays match
assert(needReadings.len() == sensors.len())

local led = hardware.pin2;
led.configure(DIGITAL_OUT, 0);


function logUpdate(what) {
    server.log(format("Got %s %0.1f", what, data[what]));
}

// Collect readings for observed devices and units.
function getReadings() {
    // Iterate through the array of sensors, 
    // collect readings for each observed unit.
    foreach (idx, sensor in sensors) {
        local readingNames = needReadings[idx];
        local tempReading = sensor.read();
        if ("err" in tempReading) {
            server.error("Error reading " + readingName + "\n" + reading.err);
        } else {
            foreach (readingName in readingNames) {
                data[readingName] = tempReading[readingName];
                logUpdate(readingName);
            }
        }
    }
    agent.send("reading", data);
    imp.wakeup(INTERVAL_SECONDS, getReadings);
}


function setLed(data) {
    if (data == 0 || data == 1) {
        server.log("led set to " + data);
        led.write(data);
    }
}

function getLed(data) {
    agent.send("led", led.read());
}

agent.on("setled", setLed);
agent.on("getled", getLed);

setLed(1);
getLed(null);

// Take readings as soon as the device starts up.
// This function schedules itself to run again in INTERVAL_SECONDS.
getReadings();
