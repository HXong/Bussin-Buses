const cron = require("node-cron");
const processTrafficData = require("../services/LTADataPollerService");
const { analyzeTraffic } = require("../services/trafficProcessorService");

let isRunning = false

/**
 * @description Run the traffic update cycle.
 * This function fetches new traffic images, analyzes traffic congestion,
 * and updates the congestion data.
 * It is scheduled to run every 3 minutes using cron.
 * To start the scheduler, run npm start:scheduler.
 * @returns {Promise<void>}
 */
async function runTrafficUpdate() {

    console.log("Running traffic update cycle...");

    if (isRunning) {
        console.log(`[${new Date().toISOString()}] Previous job is still running. Skipping this cycle.`);
        return;
    }

    isRunning = true

    try {
        console.log("Fetching new traffic images...");
        await processTrafficData();

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
