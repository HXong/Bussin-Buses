const { getDriverLocation } = require('../services/supabaseService');
const { loadActiveDrivers, saveActiveDrivers } = require('../utils/driverStore');

exports.getDriverLocation = async (req, res) => {
    const { driverId } = req.params;

    const { driverLocation, driverError } = await getDriverLocation(driverId);

    if (driverError || !driverLocation) {
        return res.status(404).json({ error: 'Driver location not found' });
    }

    let activeDrivers = loadActiveDrivers();
    let driver = activeDrivers.find(d => d.driver_id === driverId);

    if (!driver) {
        return res.status(404).json({ error: "Driver not found in active sessions" });
    }

    driver.currentLocation = [driverLocation.latitude, driverLocation.longitude];
    console.log(driver.currentLocation);

    saveActiveDrivers(activeDrivers);

    return res.json({ currentLocation: driverLocation });
};
