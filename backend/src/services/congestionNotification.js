const fs = require('fs');
const path = require('path');
const axios = require('axios');
const { decode } = require('@here/flexpolyline');

const { getRoutesNearCamera, getNearestRoutePoint } = require('./routeHandler');

const ACTIVE_DRIVERS_FILE = path.join(__dirname, '../../active_drivers.json');

const driverNotifications = {};

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
        if (!driver.onRoute) return; 

        let route = driver.scheduled_route.find(r => r.journey_started === true);

        const decodedRoute = decode(route.polyline).polyline;
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

        if (!driverNotifications[driverId]) {
            driverNotifications[driverId] = [];
        }

        //Check if driver was notified about this camera within the last 5 minutes
        const recentNotifications = driverNotifications[driverId].filter(notification =>
            notification.cameraId === cameraId &&
            (now - notification.timestamp) < 5 * 60 * 1000 
        );

        if (recentNotifications.length > 0) {
            console.log(`Skipping duplicate notification for Driver ${driverId} (Camera ${cameraId})`);
            return;
        }

        axios.post('http://localhost:3000/api/notify-driver', {
            driver_id: driverId,
            message: `🚦 High congestion detected ahead on your route (Camera ${cameraId})!`,
            cameraId: cameraId
        }).then(() => {
            console.log(`Notification sent to Driver ${driverId} (Camera ${cameraId})`)
            driverNotifications[driverId].push({ 
                message: `🚦 High congestion detected ahead!`, 
                cameraId, 
                timestamp: getSGTime()
            });

            //
            if (driverNotifications[driverId].length > 3) {
                driverNotifications[driverId].shift();
            }

        }).catch(error => {
            console.error(`Failed to notify Driver ${driverId}:`, error.message);
        });
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