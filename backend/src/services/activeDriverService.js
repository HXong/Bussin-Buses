const { loadActiveDrivers, saveActiveDrivers } = require('../model/driverStore');

/**
 * @description Load active drivers from a JSON file.
 * If the file does not exist, an empty array is returned.
 * @param {String} driver_id 
 * @returns {Object} driver
 */
function findActiveDriver(driver_id){
    const activeDrivers = loadActiveDrivers();
    const driver = activeDrivers.find(d => d.driver_id === driver_id);

    return driver;
}

/**
 * @description Update the route of an active driver.
 * If the driver is not found, it does nothing.
 * @param {String} driver_id 
 * @param {String} polyline 
 */
function updateActiveDriverRoute(driver_id, polyline){
    const activeDrivers = loadActiveDrivers();
    const driver = activeDrivers.find(d => d.driver_id === driver_id);
    driver.polyline = polyline;
    saveActiveDrivers(activeDrivers);
}

/**
 * @description Update the location of an active driver.
 * If the driver is not found, it does nothing.
 * @param {String} driver_id 
 * @param {Array} newLocation 
 * @returns {Object} driver
 */
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

/**
 * @description Update an active driver.
 * If the driver is not found, it will be added to the active drivers list.
 * If the driver is found, it will be updated.
 * The driver will be added to the active drivers list if it does not exist.
 * @param {String} driver_id 
 * @param {String} schedule_id 
 * @param {String} polyline 
 * @param {Array} currentLocation 
 * @param {Array} destination 
 */
function updateActiveDriver(driver_id, schedule_id, polyline, currentLocation, destination) {
    let activeDrivers = loadActiveDrivers();

    activeDrivers = activeDrivers.filter(d => d.driver_id !== driver_id);
    activeDrivers.push({ driver_id, schedule_id, polyline, currentLocation, destination });

    saveActiveDrivers(activeDrivers);
}

/**
 * @description Remove an active driver from the list.
 * If the driver is not found, it does nothing.
 * @param {String} driver_id 
 */
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