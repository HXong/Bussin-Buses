const fs = require('fs');
const path = require('path');
const axios = require('axios');
const { decode } = require('@here/flexpolyline');

const { getRoutesNearCamera, getNearestRoutePoint } = require('./routeHandler');
const getTime = require('./TrafficDataProcessor');

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
        if (!driver.polyline) return; // Skip if no route available

        const decodedRoute = decode(driver.polyline).polyline;
        console.log("Checking route against camera:", cameraData);

        if (getRoutesNearCamera(decodedRoute, cameraData)) {
            console.log("Enter getRouteNearCamera");
            const driverNearestIndex = getNearestRoutePoint(decodedRoute, driver.currentLocation);
            const congestionNearestIndex = getNearestRoutePoint(decodedRoute, [cameraData.lat, cameraData.lng]);
            console.log("driver Index: ", driverNearestIndex, "congestion Index: ", congestionNearestIndex);

            if (driverNearestIndex < congestionNearestIndex) {
                affectedDrivers.push(driver);
            }
        }
    });
    return affectedDrivers;
}


function sendNotification(affectedDrivers, cameraId) {
    const now = Date.now();
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
            (now - new Date(notification.timestamp).getTime()) < 5 * 60 * 1000 
        );

        if (recentNotifications.length > 0) {
            console.log(`Skipping duplicate notification for Driver ${driverId} (Camera ${cameraId})`);
            return;
        }

        console.log(`📩 Sending notification to Driver ${driverId} (Camera ${cameraId})`);

        axios.post('http://localhost:3000/api/notify-driver', {
            driver_id: driverId,
            message: `🚦 High congestion detected ahead on your route (Camera ${cameraId})!`,
            cameraId: cameraId
        }).then(() => {
            console.log(`Notification sent to Driver ${driverId} (Camera ${cameraId})`)
            driverNotifications[driverId].push({ 
                message: `🚦 High congestion detected ahead!`, 
                cameraId, 
                timestamp: getTime()
            });

            //
            if (driverNotifications[driverId].length > 3) {
                driverNotifications[driverId].shift();
            }

        }).catch(error => {
            console.error(`Failed to notify Driver ${driverId}:`, error.message);
        });

        console.log("✅ Notification sent without modifying session.");
    });
}

module.exports = { getAffectedDrivers, sendNotification };