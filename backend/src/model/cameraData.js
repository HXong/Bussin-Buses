const fs = require('fs');
const path = require('path');
const IMAGES_DIR = path.join(__dirname, '../../images');
const CONGESTION_FILE = path.join(__dirname, '../../congestion_data.json');

if (!fs.existsSync(IMAGES_DIR)) {
    fs.mkdirSync(IMAGES_DIR, { recursive: true });
}

/**
 * @description Save camera data to a JSON file.
 * This function retrieves existing data from the file, updates it with new camera data,
 * and saves it back to the file.
 * It also ensures that the directory for the images exists.
 * @param {object} cameras 
 */
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

/**
 * @description Download an image from a URL and save it to the local filesystem.
 * The image is saved in the IMAGES_DIR directory with the specified filename.
 * @param {String} url 
 * @param {String} filename 
 * @returns {Promise<String>} - The path to the downloaded image file
 */
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
