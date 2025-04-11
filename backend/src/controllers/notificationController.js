const {
    checkExistingNotification,
    insertNotification
} = require('../services/supabaseService');

/**
 * @description Notify the driver of high congestion ahead on their route.
 * Checks existing notification in the table to see whether the notification already exists
 * inserts the notification into the table if it does not exist
 * @param {String} driver_id
 * @param {String} message
 * @param {String} cameraId
 * @param {Date} timeStamp
 * @param {boolean} seen
 * @returns 
 */
exports.notifyDriver = async (req, res) => {
    const { driver_id, message, cameraId, timeStamp, seen } = req.body;

    if (!driver_id || !message || !cameraId) {
        return res.status(400).json({
            error: "Missing notification parameters (driver_id, message, cameraId required)."
        });
    }

    console.log(`Notification received for Driver ${driver_id}: ${message}`);

    const { existingNotification, checkError } = await checkExistingNotification(driver_id, cameraId);

    if (checkError && checkError.code !== 'PGRST116') {
        console.error("Error checking existing notification:", checkError.message);
        return res.status(500).json({
            error: "Error checking existing notification",
            details: checkError.message
        });
    }

    if (existingNotification) {
        return res.json({
            success: false,
            message: "Notification already exists for this camera"
        });
    }

    const insertError = await insertNotification(driver_id, cameraId, message, timeStamp, seen);

    if (insertError) {
        console.error("Error inserting notification:", insertError.message);
        return res.status(500).json({
            error: "Error inserting notification",
            details: insertError.message
        });
    }

    return res.json({ success: true, message: "Notification added" });
};
