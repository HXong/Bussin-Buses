const fs = require('fs');
const path = require('path');
const axios = require('axios');
const { decode } = require('@here/flexpolyline');

const { getRoutesNearCamera, getNearestRoutePoint } = require('./routeHandler');

const ACTIVE_DRIVERS_FILE = path.join(__dirname, '../../active_drivers.json');

//const driverNotifications = {};

function getActiveDrivers() {
    if (!fs.existsSync(ACTIVE_DRIVERS_FILE)) return [];
    try {
        return JSON.parse(fs.readFileSync(ACTIVE_DRIVERS_FILE, "utf8"));
    } catch (error) {
        console.error("Error reading active drivers JSON:", error.message);
        return [];
    }
}

function getAffectedDrivers(cameraData) {
    const activeDrivers = getActiveDrivers();
    let affectedDrivers = [];

    activeDrivers.forEach(driver => {

        let polyline = driver.polyline;

        const decodedRoute = decode(polyline).polyline;
        console.log("Checking route against camera:", cameraData);

        if (getRoutesNearCamera(decodedRoute, cameraData)) {
            const driverNearestIndex = getNearestRoutePoint(decodedRoute, driver.currentLocation);
            const congestionNearestIndex = getNearestRoutePoint(decodedRoute, [cameraData.lat, cameraData.lng]);
            if (driverNearestIndex < congestionNearestIndex) {
                affectedDrivers.push(driver);
            }
        }
    });
    return affectedDrivers;
}


function sendNotification(affectedDrivers, cameraId) {
    const now = getSGTime();
    if (!Array.isArray(affectedDrivers)) {
        console.error('affectedDrivers is not an array:', affectedDrivers);
        return;
    }

    affectedDrivers.forEach(driver => {
        const driverId = driver.driver_id;

        axios.post('http://localhost:3000/api/notify-driver', {
            driver_id: driverId,
            message: `High congestion detected ahead on your route (Camera ${cameraId})!`,
            cameraId: cameraId,
            seen: false
        })
    });
}

function getSGTime(){
    const options = {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: false,
      };

    return new Date().toLocaleString('en-SG', options);
}

module.exports = { getAffectedDrivers, sendNotification };