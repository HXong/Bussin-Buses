const fs = require('fs');
const path = require('path');
const axios = require('axios');
const fetchTrafficCameras = require('./fetchCameras');
const { type } = require('os');

//TODO: Supabase setup

const IMAGES_DIR = path.join(__dirname, '../../images');

if (!fs.existsSync(IMAGES_DIR)) {
    fs.mkdirSync(IMAGES_DIR, { recursive: true });
}

async function downloadImage(url, filename) {
    try{
        console.log(`Attempting to download: ${url}`);

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
                console.log(`Successfully downloaded: ${filePath}`);
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
console.log("fetchAndSaveImages.js is being executed...");

async function fetchAndSaveImages() {
    console.log("fetchAndSaveImages() is running...");

    console.log("Calling fetchTrafficCameras...");
    const cameras = await fetchTrafficCameras();
    console.log("Cameras received:", cameras);

    if (!cameras || cameras.length === 0) {
        console.log("No cameras found. Skipping image downloads.");
        return;
    }

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
        console.log(`Downloading: ${cam.image} → ${filename}`);

        const filePath = await downloadImage(cam.image, filename);

        if (filePath) {
            console.log(`Downloaded: ${filePath}`);
        } else {
            console.log(`Failed to download: ${cam.image}`);
        }
    });

    await Promise.all(downloadPromises);
    console.log("All images downloaded successfully.");

    return true;
}

module.exports = fetchAndSaveImages;

if (require.main === module) {
    console.log("fetchAndSaveImages.js is running as a script.");
    fetchAndSaveImages();
}
