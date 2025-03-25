const axios = require('axios');
const fs = require('fs');
const path = require('path');
const turf = require('@turf/turf');
const { decode } = require('@here/flexpolyline');
require('dotenv').config();

const CONGESTION_FILE = path.join(__dirname, '../../congestion_data.json');
const HERE_API = process.env.HERE_API_KEY;

//fetching optimised routes from API call
async function getOptimisedRoute(origin, destination, avoidCongestion = true){
    let avoidAreasQuery = "";

    if(avoidCongestion){
        const congestionAreas = getCongestionAreas();
        if(congestionAreas.length > 0){
            avoidAreasQuery = `&avoid[areas]=${congestionAreas}`;
        }
        console.log(avoidAreasQuery);
    }

    console.log(origin);
    console.log(destination);

    const url = `https://router.hereapi.com/v8/routes?&origin=${origin}${avoidAreasQuery}&destination=${destination}&transportMode=car&return=polyline&apikey=${HERE_API}`;

    try{
        const response = await axios.get(url);

        if(response.data.routes && response.data.routes.length > 0){
            const route = response.data.routes[0].sections[0];
            return route.polyline;
        } else {
            console.error("No alternative route found.");
            return null;
        }
    } catch (error) {
        console.error("Error fetching new route:", error.message);
        return null;
    }
}

//Get congestion areas from json data
function getCongestionAreas() {
    if (!fs.existsSync(CONGESTION_FILE)) return "";

    const data = JSON.parse(fs.readFileSync(CONGESTION_FILE));

    const offset = 0.001;

    const boundingBoxes = data
        .filter(entry => {
            const latest = entry.timestamps[entry.timestamps.length - 1];
            return latest && (latest.congestion_level === "high");
        })
        .map(entry => {
            const { lat, lng } = entry;
            const lat1 = lat - offset; 
            const lon1 = lng - offset; 
            const lat2 = lat + offset;
            const lon2 = lng + offset;
            return `bbox:${lon1},${lat1},${lon2},${lat2}`;
        })
        .join("|");
    
    return boundingBoxes;
}


function getRoutesNearCamera(routes, cameraData) {
    const cameraPoint = turf.point([cameraData.lng, cameraData.lat]); 
    console.log(`🎥 Checking congestion at Camera ${cameraData.id}:`, cameraData.lat, cameraData.lng);

    const formattedRoute = routes.map(coord => [coord[1], coord[0]]); 

    try {
        const routeLine = turf.lineString(formattedRoute); 
        const distance = turf.pointToLineDistance(cameraPoint, routeLine, { units: 'meters' });

        console.log(`Distance from Camera ${cameraData.id} to Route: ${distance} meters`);
        return distance <= 100;
    } catch (error) {
        console.error("Error processing route:", formattedRoute, error);
        return false;
    }
}


//Finding nearest point on route to driver's location (dynamic location to the fixed coordinates of polyline)
function getNearestRoutePoint(routeCoordinates, driverLocation) {
    let minDistance = Infinity;
    let nearestIndex = -1;

    routeCoordinates.forEach((coord, index) => {
        const distance = turf.distance(turf.point([coord[1], coord[0]]), turf.point([driverLocation[1], driverLocation[0]]), { units: 'meters' });
        if (distance < minDistance) {
            minDistance = distance;
            nearestIndex = index;
        }
    });
    return nearestIndex;
}

function decodeRoute(encodedPolyline){
  try {
    const decoded = decode(encodedPolyline).polyline; 
    return decoded;
  } catch (error) {
      console.error("Error decoding route:", error.message);
      return null;
  }
}


module.exports = {
    getOptimisedRoute,
    getRoutesNearCamera,
    getNearestRoutePoint,
    decodeRoute,
};