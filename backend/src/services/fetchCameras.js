require ('dotenv').config();
const axios = require('axios');
//const { createClient } = require('@supabase/supabase-js');

// TODO: Supabase setup
//const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_KEY);


async function fetchTrafficCameras() {
    console.log("📡 Fetching traffic camera data...");
    const API_URL = "https://api.data.gov.sg/v1/transport/traffic-images";

    try {
        const response = await axios.get(API_URL);
        const cameras = response.data.items[0].cameras;

        //For uploading to Supabase
        // for (const cam of cameras) {
        //     const { camera_id, image, location } = cam;

        //     const { data, error } = await supabase
        //         .from("traffic_data")
        //         .upsert([{ 
        //             camera_id: camera_id, 
        //             image_url: image, 
        //             latitude: location.latitude, 
        //             longitude: location.longitude
        //         }]);

        //     if (error) {
        //         console.error(`Supabase Error (Camera ID ${camera_id}):`, error.message);
        //     } else {
        //         console.log(`Camera ${camera_id} added/updated.`);
        //     }

        return cameras.map(cam => ({
            id: cam.camera_id,
            image: cam.image,
            coordinates: cam.location
        }));
    } catch (error) {
        console.error("Error fetching traffic data:", error);
        return [];
    }
}

module.exports = fetchTrafficCameras;