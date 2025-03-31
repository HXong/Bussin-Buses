const fs = require('fs');
const path = require('path');

const CONGESTION_FILE = path.join(__dirname, '../../congestion_data.json');

function loadCongestionData() {
    if (!fs.existsSync(CONGESTION_FILE)) return [];

    try {
        return JSON.parse(fs.readFileSync(CONGESTION_FILE, 'utf8'));
    } catch (error) {
        console.error("Error reading active drivers file:", error.message);
        return [];
    }
}

function saveCongestionData(congestionData) {
    try {
        fs.writeFileSync(CONGESTION_FILE, JSON.stringify(congestionData, null, 2));
    } catch (error) {
        console.error("Error saving active drivers file:", error.message);
    }
}

module.exports = {
    loadCongestionData,
    saveCongestionData
};