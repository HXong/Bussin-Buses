const fs = require('fs');
const path = require('path');
const IMAGES_DIR = path.join(__dirname, '../../images');
const CONGESTION_FILE = path.join(__dirname, '../../congestion_data.json');

if (!fs.existsSync(IMAGES_DIR)) {
    fs.mkdirSync(IMAGES_DIR, { recursive: true });
}

function saveCameraData(cameras) {
    let existingData = [];

    if (fs.existsSync(CONGESTION_FILE)) {
        existingData = JSON.parse(fs.readFileSync(CONGESTION_FILE));
    }

    const updatedData = cameras.map(cam => ({
        id: cam.id,
        image: cam.image,
        lat: cam.coordinates.latitude,
        lng: cam.coordinates.longitude,
        timestamps: []
    }));

    existingData.forEach(existing => {
        const newData = updatedData.find(cam => cam.id === existing.id);
        if (newData) {
            newData.timestamps = existing.timestamps || [];
        }
    });

    fs.writeFileSync(CONGESTION_FILE, JSON.stringify(updatedData, null, 2));
    console.log(`Traffic camera data updated with ${updatedData.length} entries.`);
}

async function downloadImage(url, filename) {
    const axios = require('axios');
    try {
        const response = await axios({
            url,
            method: "GET",
            responseType: "stream",
        });

        const filePath = path.join(IMAGES_DIR, filename);
        const writer = fs.createWriteStream(filePath);

        return new Promise((resolve, reject) => {
            response.data.pipe(writer);
            writer.on('finish', () => resolve(filePath));
            writer.on('error', error => {
                console.error(`Error writing ${filePath}:`, error.message);
                reject(null);
            });
        });
    } catch (error) {
        console.error(`Error downloading image ${url}:`, error.message);
        return null;
    }
}

module.exports = {
    saveCameraData,
    downloadImage
};
