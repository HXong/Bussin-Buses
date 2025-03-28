require('dotenv').config();
const express = require('express');
const router = express.Router();

const notificationController = require('../controllers/notificationController');
const routeController = require('../controllers/routeController');
const journeyController = require('../controllers/journeyController');
const driverController = require('../controllers/driverController');

const { triggerManualCongestion } = require('../services/TrafficDataProcessor');

/**
 * API to get the rerouted path for a driver
 * Call this API once the frontend recieves a notification
 * that there is congestion ahead on the driver's route
 * from the notification table (flutter subscribe to this table)
 * @param {string} driverId - The driver's unique identifier
 * @returns {object} - The rerouted path (polyline) and decoded route (array of coordinates)
 */
router.get('/get-reroute', routeController.getReroute);

/**
 * API to get active driver's location
 */
router.get('/get-driver-location/:driverId', driverController.getDriverLocation);

/**
 * API to start the journey for a driver
 * Gets the driver's pickup and destination locations from schedule table
 * Updates the Journey table to mark the journey as started
 * @param {string} driver_id - The driver's unique identifier
 * @param {string} schedule_id - The schedule's unique identifier
 * @returns {object} - The polyline and decoded route (array of coordinates) for the driver's journey
 */
router.post('/start-journey', journeyController.startJourney);

/**
 * API to stop the journey for a driver
 * Deletes the journey from the database
 * Updates the schedule to mark it as deleted (delete_schedule = true)
 * Deletes all notifications for the driver
 * @param {string} driver_id - The driver's unique identifier
 * @param {string} schedule_id - The schedule's unique identifier
 * @returns {object} - Success message if the journey was stopped successfully
 */
router.post('/stop-journey', journeyController.stopJourney);


/**
 * API to notify the driver of high congestion ahead on their route
 * checks existing notification in the table to see whether the notification already exists
 * inserts the notification into the table if it does not exist
 * @param {string} driver_id - The driver's unique identifier
 * @param {string} message - The notification message
 * @param {string} cameraId - The camera's unique identifier
 * @param {string} timeStamp - The timestamp of the notification
 * @param {boolean} seen - The status of the notification (seen or unseen)
 * @returns {object} - Success message if the notification was added successfully
 */
router.post('/notify-driver', notificationController.notifyDriver);

/**
 * For lab testing only
 */
app.post('/api/test-congestion', (req, res) => {
  const { cameraId } = req.body;
  triggerManualCongestion(cameraId);
  res.send({ status: 'Manual congestion triggered' });
});

module.exports = router;