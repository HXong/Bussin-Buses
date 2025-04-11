const fs = require('fs');
const path = require('path');

const ACTIVE_DRIVERS_FILE = path.join(__dirname, '../../active_drivers.json');

/**
 * @description Load active drivers from a JSON file.
 * If the file does not exist, an empty array is returned.
 * @returns {Array} - Array of active drivers
 */
function loadActiveDrivers() {
    if (!fs.existsSync(ACTIVE_DRIVERS_FILE)) return [];

    try {
        return JSON.parse(fs.readFileSync(ACTIVE_DRIVERS_FILE, 'utf8'));
    } catch (error) {
        console.error("Error reading active drivers file:", error.message);
        return [];
    }
}

/**
 * @description save active drivers to a JSON file.
 * if the file does not exist, it will be created.
 * if the file exists, it will be overwritten.
 * @param {Array} activeDrivers 
 */
function saveActiveDrivers(activeDrivers) {
    try {
        fs.writeFileSync(ACTIVE_DRIVERS_FILE, JSON.stringify(activeDrivers, null, 2));
    } catch (error) {
        console.error("Error saving active drivers file:", error.message);
    }
}

module.exports = {
    loadActiveDrivers,
    saveActiveDrivers
};