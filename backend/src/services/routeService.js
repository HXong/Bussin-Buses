const axios = require('axios');
const turf = require('@turf/turf');
const { loadCongestionData } = require('../utils/congestionStore');
const { decode } = require('@here/flexpolyline');
require('dotenv').config();

const HERE_API = process.env.HERE_API_KEY;

//fetching optimised routes from API call
async function getOptimisedRoute(origin, destination, avoidCongestion = true) {
    let avoidAreasQuery = "";

    if (avoidCongestion) {
        const congestionAreas = getCongestionAreas();
        if (congestionAreas.length > 0) {
            avoidAreasQuery = `&avoid[areas]=${congestionAreas}`;
        }
    }

    const url = `https://router.hereapi.com/v8/routes?origin=${origin}${avoidAreasQuery}&destination=${destination}&transportMode=car&return=summary,polyline&apikey=${HERE_API}`;

    try {
        const response = await axios.get(url);
        if (response.data.routes && response.data.routes.length > 0) {
            const route = response.data.routes[0].sections[0];
            return {
                polyline: route.polyline,
                duration: route.summary.duration
            };
        } else {
            console.error("No alternative route found.");
            return null;
        }
    } catch (error) {
        console.error("Error fetching new route:", error.message);
        return null;
    }
}

// Retrieve congestion areas in bounding box format from latest JSON data
function getCongestionAreas() {
    const data = loadCongestionData();
    const offset = 0.001;

    return data
        .filter(entry => {
            const latest = entry.timestamps?.[entry.timestamps.length - 1];
            return latest?.congestion_level === "high";
        })
        .map(entry => {
            const { lat, lng } = entry;
            return `bbox:${lng - offset},${lat - offset},${lng + offset},${lat + offset}`;
        })
        .join("|");
}

// Check if camera lies within 100 meters of a given route
function getRoutesNearCamera(routeCoords, cameraData) {
    const cameraPoint = turf.point([cameraData.lng, cameraData.lat]);
    const formattedRoute = routeCoords.map(coord => [coord[1], coord[0]]); // lat, lng

    try {
        const routeLine = turf.lineString(formattedRoute);
        const distance = turf.pointToLineDistance(cameraPoint, routeLine, { units: 'meters' });
        return distance <= 100;
    } catch (error) {
        console.error("Error processing route:", error);
        return false;
    }
}

// Find index of nearest point on a route to the given driver location
function getNearestRoutePoint(routeCoords, driverLocation) {
    let minDistance = Infinity;
    let nearestIndex = -1;

    routeCoords.forEach((coord, index) => {
        const distance = turf.distance(
            turf.point([coord[1], coord[0]]),
            turf.point([driverLocation[1], driverLocation[0]]),
            { units: 'meters' }
        );
        if (distance < minDistance) {
            minDistance = distance;
            nearestIndex = index;
        }
    });
    return nearestIndex;
}

// Decode HERE API polyline
function decodeRoute(encodedPolyline) {
    try {
        return decode(encodedPolyline).polyline;
    } catch (error) {
        console.error("Error decoding route:", error.message);
        return null;
    }
}

module.exports = {
    getOptimisedRoute,
    getCongestionAreas,
    getRoutesNearCamera,
    getNearestRoutePoint,
    decodeRoute
};
