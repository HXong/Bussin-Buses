const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');
const { time } = require('console');

//TODO: Supabase setup

const IMAGES_DIR = path.join(__dirname, "../../images");
const PYTHON_PATH = "C:/Python312/python.exe"

const MAX_CONCURRENT_PROCESSES = Math.max(1, os.cpus().length / 2);

async function countCars(imagePath){ //cameraId) { to be included
    return new Promise((resolve, reject) => {
        const pythonProcess = spawn(PYTHON_PATH, ['src/scripts/count_cars.py', imagePath]);

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

                    //update supabase
                    // console.log(`Image: ${imagePath} → Vehicles: ${result.vehicle}, Congestion: ${result.congestion_level}`);
                    // await updateSupabase(cameraId, imageUrl);

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

//Updates supabase with congestion level
// async function updateSupabase(cameraId, result) {
//     try{
//         const { data, error } = await supabase
//             .from('traffic_data')
//             .update({
//                 vehicle_count: result.vehicle,
//                 road_area_pixels: result.road_area,
//                 vehicle_area_pixels: result.vehicle_area,
//                 congestion_level: result.congestion_level,
//                 timestamp: new Date().toISOString(),
//             })
//             .eq('camera_id', cameraId);
        
//         if (error) throw error;
//         console.log(`Supabase updated for Camera ID ${cameraId}`);
//     } catch (error) {
//         console.error(`Error updating Supabase: ${error.message}`);
//     }
// }

async function analyzeTraffic() {
    console.log("Starting traffic analysis...");

    const files = fs.readdirSync(IMAGES_DIR).filter(file => file.endsWith(".jpg"));
    if (files.length === 0) {
        console.log("No images found for analysis.");
        return;
    }

    //fetch cameras from supabase
    // const { data: cameras } = await supabase.from("traffic_data").select("camera_id, image_url");
    // const cameraMap = new Map(cameras.map(c => [c.image_url, c.camera_id]));

    const queue = [...files];
    const activeProcesses = [];

    while (queue.length > 0 || activeProcesses.length > 0) {
        while (queue.length > 0 && activeProcesses.length < MAX_CONCURRENT_PROCESSES) {
            const file = queue.shift();
            const filePath = path.join(IMAGES_DIR, file);

            //retrieve camera ID from image URL
            // const cameraId = cameraMap.get(filePath);

            // if (!cameraId) {
            //     console.error(`Camera ID not found for ${file}`);
            //     continue;
            // }

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
    
    // for (const file of files) { 
    //     const filePath = path.join(IMAGES_DIR, file);

    //     try {
    //         const result = await countCars(filePath);
    //         console.log(`Processed ${file} → Vehicles: ${result.vehicle}, Congestion: ${result.congestion_level}`);
    //     } catch (error) {
    //         console.error(`Error processing ${file}: ${error.message}`);
    //     }
    // }
}


module.exports = analyzeTraffic;