const fetchTrafficCameras = require('./fetchCameraService');
const { saveCameraData, downloadImage } = require('../model/cameraData');

async function processTrafficData() {

    const cameras = await fetchTrafficCameras();

    if (!cameras || cameras.length === 0) {
        console.log("No cameras found. Skipping image downloads.");
        return;
    }

    saveCameraData(cameras);
    
    const downloadPromises = cameras.map(async cam => {
        const filename = `${cam.id}.jpg`;

        const filePath = await downloadImage(cam.image, filename);

        if (!filePath) {
            console.log(`Failed to download: ${cam.image}`);
        } 
    });

    await Promise.all(downloadPromises);

    return true;
}

module.exports = processTrafficData;

if (require.main === module) {
    console.log("LTADataPoller.js is running as a script.");
    processTrafficData();
}
