const routeService = require('../services/routeService');
const { getDriverLocation, getStartJourneyDriver, getLocationCoordinates, updateScheduleETA } = require('../services/supabaseService');
const { findActiveDriver, updateActiveDriverRoute } = require('../services/activeDriverService');

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

        const driver = findActiveDriver(driverId);

        driver.currentLocation = [driverLocation.latitude, driverLocation.longitude];

        const originCoords = `${driverLocation.latitude},${driverLocation.longitude}`;
        const destinationCoords = driver.destination;

        const { polyline, duration } = await routeService.getOptimisedRoute(originCoords, destinationCoords);

        if (!polyline || !duration) {
            return res.status(404).json({ error: "No route found." });
        }

        const etaInMinutes = Math.ceil(duration / 60);

        const updateError = await updateScheduleETA(driver.schedule_id, etaInMinutes);
        if (updateError) {
            throw updateError;
        }

        updateActiveDriverRoute(driverId, polyline);

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

exports.getETA = async (req, res) => {
    try{
        const { driver_id, schedule_id } = req.body;

        if (!driver_id || !schedule_id) {
            return res.status(400).json({ error: 'Origin and destination are required' });
        }

        const { driver, driverError } = await getStartJourneyDriver(driver_id, schedule_id);
        if (!driver || driverError) {
            return res.status(404).json({ error: "Driver or route not found" });
        }

        const { locationData: originData, locationError: originError } = await getLocationCoordinates(driver.pickup);
        if (originError) return res.status(404).json({ error: "Origin not found" });

        const { locationData: destinationData, locationError: destinationError } = await getLocationCoordinates(driver.destination);
        if (destinationError) return res.status(404).json({ error: "Destination not found" });

        const originCoords = `${originData.latitude},${originData.longitude}`;
        const destinationCoords = `${destinationData.latitude},${destinationData.longitude}`;

        const { polyline, duration } = await routeService.getOptimisedRoute(originCoords, destinationCoords);
        if (!polyline || !duration) {
            return res.status(404).json({ error: "No optimized route found" });
        }

        const etaInMinutes = Math.ceil(duration / 60);

        const updateError = await updateScheduleETA(schedule_id, etaInMinutes);
        if (updateError) {
            throw updateError;
        }

        return res.status(200).json({ success: true });

    } catch (error) {
        res.status(500).json({ error: 'Error fetching route data', details: error.message });
    }
}
