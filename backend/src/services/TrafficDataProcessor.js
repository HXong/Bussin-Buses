const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');
const { getAffectedDrivers, sendNotification } = require("./congestionNotification");

//TODO: Supabase setup

//Local storage
const CONGESTION_FILE = path.join(__dirname, '../../congestion_data.json');

const IMAGES_DIR = path.join(__dirname, "../../images");
const PYTHON_PATH = "C:/Python312/python.exe"

const MAX_CONCURRENT_PROCESSES = Math.max(1, os.cpus().length / 2);

async function countCars(imagePath){ 
    return new Promise((resolve, reject) => {
        const pythonProcess = spawn(PYTHON_PATH, ['src/scripts/count_cars.py', imagePath]);
        const cameraId = imagePath.split("\\").pop().split(".")[0];

        let output = "";
        let errorOutput = "";

        pythonProcess.stdout.on('data', (data) => {
            const line = data.toString().trim();

            if(line.startsWith("{") && line.endsWith("}")){
                output = line;
            }
        });

        pythonProcess.stderr.on('data', (data) => {
            errorOutput += data.toString();
        });

        pythonProcess.on("close", (code) => {
            if (code !== 0 || errorOutput) {
                console.error(`Python Error: ${errorOutput}`);
                reject(new Error(`Python script failed: ${errorOutput}`));
            } else {
                try {
                    const result = JSON.parse(output.trim());
                    console.log(`Processed ${imagePath} → Vehicles: ${result.vehicle}, Congestion: ${result.congestion_level}`);

                    let congestionData = [];
                    if (fs.existsSync(CONGESTION_FILE)) {
                        try {
                            congestionData = JSON.parse(fs.readFileSync(CONGESTION_FILE, "utf8"));
                        } catch (error) {
                            console.error("Error reading JSON file:", error.message);
                            congestionData = [];
                        }
                    }


                    if(result.congestion_level === 'high'){
                        console.log("entering congestion notification...");
                        congestionData.forEach(camera => {
                            if(camera.id === cameraId){
                                const affectedDrivers =  getAffectedDrivers(camera);
                                if (affectedDrivers.length > 0) {
                                    try {
                                        sendNotification(affectedDrivers, cameraId);
                                    } catch (error) {
                                        console.error('Error sending notification:', error);
                                    }
                                }
                            }
                        });
                    }

                    updateCongestionData(congestionData, cameraId, result.congestion_level);
                    resolve(result);
                } catch (error) {
                    reject(new Error(`JSON Parsing Error: ${output}`));
                }
            }
        });

        pythonProcess.on("exit", () => {
            console.log(`Process for ${imagePath} exited.`);
        });
    });
}

async function analyzeTraffic() {

    const files = fs.readdirSync(IMAGES_DIR).filter(file => file.endsWith(".jpg"));
    if (files.length === 0) {
        console.log("No images found for analysis.");
        return;
    }

    if (!fs.existsSync(CONGESTION_FILE)) {
        console.log("No congestion data file found.");
        return;
    }

    const queue = [...files];
    const activeProcesses = [];

    while (queue.length > 0 || activeProcesses.length > 0) {
        while (queue.length > 0 && activeProcesses.length < MAX_CONCURRENT_PROCESSES) {
            const file = queue.shift();
            const filePath = path.join(IMAGES_DIR, file);

            const processPromise = countCars(filePath) //cameraId) to be included
                .catch(error => {
                    console.error(`Error processing ${file}: ${error.message}`);
                })
                .finally(() => {
                    activeProcesses.splice(activeProcesses.indexOf(processPromise), 1);
                });

            activeProcesses.push(processPromise);
        }
        await Promise.race(activeProcesses);
    }
    console.log("Traffic analysis completed.");
    return true;
}

async function triggerManualCongestion(cameraId) {
    console.log("Manually triggering high congestion...");
    const result = { congestion_level: 'high' };

    let congestionData = [];
    if (fs.existsSync(CONGESTION_FILE)) {
        try {
            congestionData = JSON.parse(fs.readFileSync(CONGESTION_FILE, "utf8"));
        } catch (error) {
            console.error("Error reading JSON file:", error.message);
            congestionData = [];
        }
    }

    if(result.congestion_level === 'high') {
        console.log("entering congestion notification...");
        for (const camera of congestionData) {
            if (camera.id === cameraId) {
                try {
                    const affectedDrivers = await getAffectedDrivers(camera);
                    if (affectedDrivers.length > 0) {
                        sendNotification(affectedDrivers, cameraId);
                    } else {
                        console.log("No affected drivers found.");
                    }
                } catch (error) {
                    console.error("Error during notification process:", error.message);
                }
            }
        }
    }
}

function updateCongestionData(data, cameraId, congestionLevel) {
    const timestamp = getSGTime();
    const entry = data.find(cam => cam.id === cameraId);

    if (!entry) {
        console.error(`Camera ID ${cameraId} not found in data.`);
        return;
    }

    entry.timestamps.push({ congestion_level: congestionLevel, timestamp });

    if (entry.timestamps.length > 3) {
        entry.timestamps.shift();
    }

    console.log(`Updated Camera ${cameraId} with congestion level: ${congestionLevel}`);

    try {
        fs.writeFileSync(CONGESTION_FILE, JSON.stringify(data, null, 2));
    } catch (error) {
        console.error("Error writing to JSON file:", error.message);
    }
}

function getSGTime(){
    const options = {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: true,
        timeZone: 'Asia/Singapore'
      };

    let sgTime = new Date().toLocaleString('en-SG', options);

    let [date, time] = sgTime.split(", ");
    let [month, day, year] = date.split("/");

    return `${day}/${month}/${year} ${time}`;
}


module.exports = { analyzeTraffic, triggerManualCongestion };
if (require.main === module) {
    console.log("TrafficDataProcessor.js is running as a script.");
    analyzeTraffic();
}