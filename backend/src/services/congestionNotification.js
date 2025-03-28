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
    const activeDrivers = getActiveDrivers();
    let affectedDrivers = [];

    for (const driver of activeDrivers) {

        let polyline = driver.polyline;
        const decodedRoute = decode(polyline).polyline;

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
            message: `Rerouting due to congestion at camera ${cameraId}`,
            cameraId: cameraId,
            timeStamp: now,
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
        hour12: true,
        timeZone: 'Asia/Singapore'
      };

    let sgTime = new Date().toLocaleString('en-SG', options);

    let [date, time] = sgTime.split(", ");
    let [month, day, year] = date.split("/");

    return `${day}/${month}/${year} ${time}`;
}

module.exports = { getAffectedDrivers, sendNotification };