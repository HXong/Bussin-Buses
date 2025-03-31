const { getDriverLocation } = require('../services/supabaseService');
const { updateActiveDriverLocation } = require('../services/activeDriverService');

exports.getDriverLocation = async (req, res) => {
    const { driverId } = req.params;

    const { driverLocation, driverError } = await getDriverLocation(driverId);

    if (driverError || !driverLocation) {
        return res.status(404).json({ error: 'Driver location not found' });
    }

    
    const driver = updateActiveDriverLocation(driverId, [driverLocation.latitude, driverLocation.longitude]);

    if (!driver) {
        return res.status(404).json({ error: "Driver not found in active sessions" });
    }

    return res.json({ currentLocation: driverLocation });
};
