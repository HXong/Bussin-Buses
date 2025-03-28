const fs = require('fs');
const path = require('path');
const axios = require('axios');
const fetchTrafficCameras = require('./fetchCameras');
const { type } = require('os');

//TODO: Supabase setup

const IMAGES_DIR = path.join(__dirname, '../../images');

//Local storage (temp)
const CONGESTION_FILE = path.join(__dirname, '../../congestion_data.json');

if (!fs.existsSync(IMAGES_DIR)) {
    fs.mkdirSync(IMAGES_DIR, { recursive: true });
}

function saveCameraData(cameras){
    let existingData = [];

    if(fs.existsSync(CONGESTION_FILE)){
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
    console.log(Date(Date.now()).toString())
    console.log(`Traffic camera data updated with ${updatedData.length} entries.`);
}

async function downloadImage(url, filename) {
    try{
        const response = await axios({
            url,
            method: "GET",
            responseType: "stream",
        });

        const filePath = path.join(IMAGES_DIR, filename);
        const writer = fs.createWriteStream(filePath);
        return new Promise((resolve, reject) => {
            response.data.pipe(writer);

            writer.on('finish', () => {
                resolve(filePath);
            });

            writer.on('error', (error) => {
                console.error(`Error writing ${filePath}:`, error.message);
                reject(null);
            });
        });
    } catch (error) {
        console.error(`Error downloading image ${url}:`, error.message);
        return null;
    }
}

// Upload an Image to Supabase Storage
// async function uploadToSupabase(filePath, cameraId) {
//     try{
//         const fileStream = fs.createReadStream(filePath);
//         const { data, error } = await supabase.storage
//             .from('traffic_images')
//             .upload(`${cameraId}.jpg`, fileStream, {contentType: 'image/jpeg', upsert: true});
        
//         if (error) throw error;

//         const supabaseImageUrl = `${SUPABASE_URL}/storage/v1/object/public/traffic-images/${cameraId}.jpg`;
//         console.log(`Uploaded to Supabase: ${supabaseImageUrl}`);
//         return supabaseImageUrl;
//     } catch (error) {
//         console.error(`Error uploading to Supabase: ${error.message}`);
//         return null;
//     }
// }

//Updates supabase with the image URL
// async function updateSupabase(cameraId, imageUrl) {
//     try{
//         const { data, error } = await supabase
//             .from('traffic_data')
//             .update({ image_url: imageUrl })
//             .eq('camera_id', cameraId);
        
//         if (error) throw error;
//         console.log(`Camera ${cameraId} added/updated.`);
//     } catch (error) {
//         console.error(`Error updating Supabase: ${error.message}`);
//     }
// }

//Deletes local image file after uploading
// async function deleteLocalImage(filePath) {
//     try{
//         fs.unlinkSync(filePath);
//         console.log(`Deleted: ${filePath}`);
//     } catch (error) {
//         console.error(`Error deleting ${filePath}: ${error.message}`);
//     }
// }

async function processTrafficData() {

    const cameras = await fetchTrafficCameras();

    if (!cameras || cameras.length === 0) {
        console.log("No cameras found. Skipping image downloads.");
        return;
    }

    //local storage
    saveCameraData(cameras);

    //Supabase upload setup
    // const localFilePath = await downloadImage(cam.image, filename);

    // if(localFilePath){
    //     const supabaseUrl = await uploadToSupabase(localFilePath, cam.id);
    //     if(supabaseUrl){
    //         await updateSupabase(cam.id, supabaseUrl);
    //     }
    //     deleteLocalImage(localFilePath);
    // }
    
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
