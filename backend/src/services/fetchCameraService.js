require('dotenv').config();
const axios = require('axios');

/**
 * @description Fetch traffic camera data from the API.
 * @returns {Promise<Array>} - Array of traffic camera data
 */
async function fetchTrafficCameras() {
    console.log("Fetching traffic camera data...");

    const API_URL = "https://api.data.gov.sg/v1/transport/traffic-images/?date_time=2025-03-26T18:00:00"; 
    //remove ?date_time=2025-03-26T18:00:00 for live data (this is a test input data for presentation only)

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
