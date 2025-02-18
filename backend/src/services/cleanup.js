const cron = require("node-cron");

//TODO supabase setup

// async function deleteOldImages() {
//     console.log("🗑️ Starting cleanup of old images...");

//     const { data: cameras, error } = await supabase.from("traffic_data").select("camera_id, timestamp");

//     if (error) {
//         console.error(`Supabase Error: ${error.message}`);
//         return;
//     }

//     //Filter cameras with images older than 24 hours
//     const oldCameras = cameras.filter(cam => {
//         const timeElapsed = (new Date() - new Date(cam.timestamp)) / (1000 * 60 * 60);
//         return timeElapsed > 24;
//     });

//     for (const camera of oldCameras) {
//         const { error: deleteError } = await supabase.storage
//             .from("traffic-images")
//             .remove([`${camera.camera_id}.jpg`]);

//         if (deleteError) {
//             console.error(`Failed to delete image for Camera ${camera.camera_id}:`, deleteError.message);
//         } else {
//             console.log(`Deleted old image for Camera ${camera.camera_id}`);
//         }
//     }

//     console.log("Cleanup completed.");
// }

// //deletes at midnight daily (can change if want)
// cron.schedule("0 0 * * *", () => {
//     console.log("Running scheduled cleanup...");
//     deleteOldImages();
// });