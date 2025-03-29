require('dotenv').config();
const axios = require('axios');

async function fetchTrafficCameras() {
    console.log("Fetching traffic camera data...");

    const API_URL = "https://api.data.gov.sg/v1/transport/traffic-images/?date_time=2025-03-26T18:00:00";

    try {
        const response = await axios.get(API_URL);
        const cameras = response.data.items[0].cameras;

        return cameras.map(cam => ({
            id: cam.camera_id,
            image: cam.image,
            coordinates: cam.location
        }));
    } catch (error) {
        console.error("Error fetching traffic data:", error.message);
        return [];
    }
}

module.exports = { fetchTrafficCameras };
