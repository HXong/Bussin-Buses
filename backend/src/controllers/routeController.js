const routeService = require('../services/routeService');
const { getDriverLocation } = require('../services/supabaseService');
const { loadActiveDrivers, saveActiveDrivers } = require('../utils/driverStore');

exports.getReroute = async (req, res) => {
    try {
        const { driverId } = req.query;

        if (!driverId) {
            return res.status(400).json({ error: "Missing parameters: driver id required." });
        }

        const { driverLocation, driverError } = await getDriverLocation(driverId);

        if (driverError || !driverLocation) {
            return res.status(404).json({ error: "No driver location found" });
        }

        const activeDrivers = loadActiveDrivers();
        const driver = activeDrivers.find(d => d.driver_id === driverId);

        driver.currentLocation = [driverLocation.latitude, driverLocation.longitude];

        const originCoords = `${driverLocation.latitude},${driverLocation.longitude}`;
        const destinationCoords = driver.destination;

        const { polyline, duration } = await routeService.getOptimisedRoute(originCoords, destinationCoords);

        if (!polyline || !duration) {
            return res.status(404).json({ error: "No route found." });
        }

        driver.polyline = polyline;
        saveActiveDrivers(activeDrivers);

        const decodedRoute = routeService.decodeRoute(polyline);

        res.json({
            duration,
            polyline,
            decodedRoute
        });

    } catch (error) {
        res.status(500).json({ error: 'Error fetching route data', details: error.message });
    }
};
