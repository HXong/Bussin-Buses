const axios = require('axios');

const { decodeRoute, getRoutesNearCamera, getNearestRoutePoint } = require('./routeService');
const { loadActiveDrivers } = require('../model/driverStore');
const { getSGTime } = require('../utils/timeUtils');

/**
 * @description Get the current location of a driver.
 * This function fetches the driver's location from the database.
 * @route GET /api/get-driver-location/:driverId
 * @param {String} driverId 
 * @returns {Object} driverLocation
 */
async function getDriverLocation(driverId) {
    try {
        const response = await axios.get(`http://localhost:3000/api/get-driver-location/${driverId}`);
        return response.data.currentLocation;
    } catch (error) {
        console.error(`Failed to fetch location for driver ${driverId}:`, error.message);
        return null;
    }
}

/**
 * @description Get the affected drivers based on camera data.
 * This function checks if the driver's route is near the camera location and if the driver is on the route towards the camera.
 * If so, it adds the driver to the affected drivers list.
 * @param {List<Object>} cameraData 
 * @returns {List<Object>} affectedDrivers
 */
async function getAffectedDrivers(cameraData) {
    const activeDrivers = loadActiveDrivers();
    let affectedDrivers = [];

    for (const driver of activeDrivers) {

        let polyline = driver.polyline;
        const decodedRoute = decodeRoute(polyline);

        if (getRoutesNearCamera(decodedRoute, cameraData)) {
            const currentLocation = await getDriverLocation(driver.driver_id);
            if (!currentLocation) continue;
            driver.currentLocation = [currentLocation.latitude, currentLocation.longitude];

            const driverNearestIndex = getNearestRoutePoint(decodedRoute, driver.currentLocation);
            const congestionNearestIndex = getNearestRoutePoint(decodedRoute, [cameraData.lat, cameraData.lng]);
            if (driverNearestIndex < congestionNearestIndex) {
                affectedDrivers.push(driver);
            }
        }
    }
    return affectedDrivers;
}

/**
 * @description send a notification to the affected drivers.
 * This function sends a notification to the affected drivers using the axios library.
 * It is then updated on the notification table in the supabase.
 * Frontend supscribe to this table and listen for changes.
 * @route POST /api/notify-driver
 * @param {List<Object>} affectedDrivers 
 * @param {String} cameraId 
 * @returns {Promise<void>} - Sends a notification to the affected drivers
 */
async function sendNotification(affectedDrivers, cameraId) {
    const now = getSGTime();

    if (!Array.isArray(affectedDrivers)) {
        console.error('affectedDrivers is not an array:', affectedDrivers);
        return;
    }

    for (const driver of affectedDrivers) {
        try {
            await axios.post('http://localhost:3000/api/notify-driver', {
                driver_id: driver.driver_id,
                message: `Rerouting due to congestion at camera ${cameraId}`,
                cameraId,
                timeStamp: now,
                seen: false
            });
        } catch (err) {
            console.error(`Failed to notify driver ${driver.driver_id}`, err.message);
        }
    }
}

module.exports = {
    getAffectedDrivers,
    sendNotification
};