const { loadActiveDrivers, saveActiveDrivers } = require('../model/driverStore');

function findActiveDriver(driver_id){
    const activeDrivers = loadActiveDrivers();
    const driver = activeDrivers.find(d => d.driver_id === driver_id);

    return driver;
}

function updateActiveDriverRoute(driver_id, polyline){
    const activeDrivers = loadActiveDrivers();
    const driver = activeDrivers.find(d => d.driver_id === driver_id);
    driver.polyline = polyline;
    saveActiveDrivers(activeDrivers);
}

function updateActiveDriverLocation(driver_id, newLocation){
    let activeDrivers = loadActiveDrivers();
    let driver = activeDrivers.find(d => d.driver_id === driver_id);

    if (!driver) {
        return null;
    }

    driver.currentLocation = newLocation;
    saveActiveDrivers(activeDrivers);

    return driver;
}

function updateActiveDriver(driver_id, schedule_id, polyline, currentLocation, destination) {
    let activeDrivers = loadActiveDrivers();

    activeDrivers = activeDrivers.filter(d => d.driver_id !== driver_id);
    activeDrivers.push({ driver_id, schedule_id, polyline, currentLocation, destination });

    saveActiveDrivers(activeDrivers);
}

function removeActiveDriver(driver_id){
    let activeDrivers = loadActiveDrivers();

    activeDrivers = activeDrivers.filter(d => d.driver_id !== driver_id);

    saveActiveDrivers(activeDrivers);
}

module.exports = {
    findActiveDriver,
    updateActiveDriverRoute,
    updateActiveDriverLocation,
    updateActiveDriver,
    removeActiveDriver
};