const axios = require('axios');

const { decodeRoute, getRoutesNearCamera, getNearestRoutePoint } = require('./routeService');
const { loadActiveDrivers } = require('../model/driverStore');
const { getSGTime } = require('../utils/timeUtils');

async function getDriverLocation(driverId) {
    try {
        const response = await axios.get(`http://localhost:3000/api/get-driver-location/${driverId}`);
        return response.data.currentLocation;
    } catch (error) {
        console.error(`Failed to fetch location for driver ${driverId}:`, error.message);
        return null;
    }
}

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