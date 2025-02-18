const cron = require("node-cron");
const fetchAndSaveImages = require("./fetchAndSaveImages");
const analyzeTraffic = require("./detectCongestion");

let isRunning = false

async function runTrafficUpdate() {

    console.log("Running traffic update cycle...");

    if (isRunning) {
        console.log(`⚠️ [${new Date().toISOString()}] Previous job is still running. Skipping this cycle.`);
        return;
    }

    isRunning = true

    try {
        console.log("Fetching new traffic images...");
        await fetchAndSaveImages();

        console.log("Analyzing traffic congestion...");
        await analyzeTraffic();

        console.log("Traffic update cycle completed.");
    } catch (error) {
        console.error("Error in traffic update cycle:", error);
    } finally {
        isRunning = false
    }
}


cron.schedule("*/3 * * * *", () => {
    console.log(`\nScheduled Task: Running traffic update at ${new Date().toISOString()}...`);
    runTrafficUpdate();
});

runTrafficUpdate();
