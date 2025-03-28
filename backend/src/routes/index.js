require('dotenv').config();
const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const { triggerManualCongestion } = require('../services/TrafficDataProcessor');
const { getOptimisedRoute, decodeRoute } = require('../services/routeHandler');
const { 
    getStartJourneyDriver, hasJourneyStarted, updateJourneyStarted, 
    getLocationCoordinates, getDriverLocation, deleteJourney, deleteSchedule, 
    deleteNotifcation, checkExistingNotification, insertNotification
} = require('../services/supabaseService');

const ACTIVE_DRIVERS_FILE = path.join(__dirname, '../../active_drivers.json');
const app = express();
const port = process.env.PORT || 3000;

app.use(cors())
app.use(express.json());

function loadActiveDrivers() {
  if (!fs.existsSync(ACTIVE_DRIVERS_FILE)) return [];
  return JSON.parse(fs.readFileSync(ACTIVE_DRIVERS_FILE, 'utf8'));
}

function saveActiveDrivers(activeDrivers) {
  fs.writeFileSync(ACTIVE_DRIVERS_FILE, JSON.stringify(activeDrivers, null, 2));
}

app.get('/api/scheduled-routes/:driverId', async (req, res) => {
  try {
      const driverId = req.params.driverId;

      const { data: schedules, error } = await supabase
          .from('schedules')
          .select('schedule_id, pickup, destination, date, time')
          .eq('driver_id', driverId);

      if (error) {
          console.error("Error fetching schedules:", error.message);
          return res.status(500).json({ error: "Error retrieving schedules", details: error.message });
      }

      if (!schedules || schedules.length === 0) {
          return res.json({ scheduled_route: [] }); 
      }

      const scheduleIds = schedules.map(s => s.schedule_id);

      const { data: journeys, error: journeyError } = await supabase
          .from('journey')
          .select('schedule_id, journey_started')
          .in('schedule_id', scheduleIds);

      if (journeyError) {
          console.error("Error fetching journey statuses:", journeyError.message);
          return res.status(500).json({ error: "Error retrieving journey statuses", details: journeyError.message });
      }

      const journeyMap = journeys.reduce((map, journey) => {
          map[journey.schedule_id] = journey.journey_started;
          return map;
      }, {});

      const formattedRoutes = schedules.map(schedule => ({
          schedule_id: schedule.schedule_id,
          pickup: schedule.pickup,
          destination: schedule.destination,
          date: schedule.date,
          time: schedule.time,
          journey_started: journeyMap[schedule.schedule_id] || false
      }));

      res.json({ scheduled_route: formattedRoutes });

  } catch (error) {
      console.error("Internal Server Error:", error.message);
      res.status(500).json({ error: "Internal Server Error", details: error.message });
  }
});

/**
 * API to get the rerouted path for a driver
 * Call this API once the frontend recieves a notification
 * that there is congestion ahead on the driver's route
 * from the notification table (flutter subscribe to this table)
 * @param {string} driverId - The driver's unique identifier
 * @returns {object} - The rerouted path (polyline) and decoded route (array of coordinates)
 */
app.get('/api/get-reroute', async(req, res) => {

  try{
    const { driverId } = req.query;

    if (!driverId) {
        return res.status(400).json({ error: "Missing parameters: driver id required." });
    }

    const { driverLocation: driverLocation, driverError: driverError } = await getDriverLocation(driverId);

    if (driverError || !driverLocation) {
      return res.status(404).json({ error: "No driver location found" });
    }

    const activeDrivers = loadActiveDrivers();
    const driver = activeDrivers.find(d => d.driver_id === driverId);
    driver.currentLocation = [driverLocation.latitude, driverLocation.longitude];


    const originCoords = `${driverLocation.latitude},${driverLocation.longitude}`;
    const destinationCoords = driver.destination;

    console.log(`Resolved Coordinates: Origin(${originCoords}) → Destination(${destinationCoords})`);

    const {polyline, duration} = await getOptimisedRoute(originCoords, destinationCoords);
    if (!polyline || !duration) {
        return res.status(404).json({ error: "No route found." });
    }

    driver.polyline = polyline;
    saveActiveDrivers(driver);

    const decodedRoute = decodeRoute(polyline);

    res.json({
        duration: duration,
        polyline: polyline,
        decodedRoute: decodedRoute
    });

  } catch (error){
    res.status(500).json({ error: 'Error fetching route data', details: error.message });
  }
});


app.get('/api/get-driver-location/:driverId', async (req, res) => {
  const { driverId } = req.params;

  const { driverLocation: driverLocation, driverError: driverError } = await getDriverLocation(driverId);

  if (driverError || !driverLocation) {
      return res.status(404).json({ error: 'Driver location not found' });
  }

  let activeDrivers = loadActiveDrivers();
  activeDrivers = activeDrivers.find(d => d.driver_id === driverId);
  if (!activeDrivers) {
      return res.status(404).json({ error: "Driver not found in active sessions" });
  }

  activeDrivers.currentLocation = [driverLocation.latitude, driverLocation.longitude];
  console.log(activeDrivers.currentLocation);

  saveActiveDrivers(activeDrivers);

  res.json({ currentLocation: driverLocation });
});

/**
 * API to start the journey for a driver
 * Gets the driver's pickup and destination locations from schedule table
 * Updates the Journey table to mark the journey as started
 * @param {string} driver_id - The driver's unique identifier
 * @param {string} schedule_id - The schedule's unique identifier
 * @returns {object} - The polyline and decoded route (array of coordinates) for the driver's journey
 */
app.post('/api/start-journey', async (req, res) => {
  try {
      const { driver_id, schedule_id } = req.body;
      const currentLocation = [1.335128, 103.937533];
    
      const {driver, driverError} = await getStartJourneyDriver(driver_id, schedule_id);

      if (!driver || driverError) {
          return res.status(404).json({ error: "Driver or route not found" });
      }

      const {journeyStart, error} = await hasJourneyStarted(schedule_id);
      
      if (!journeyStart || error) {
        console.error("Error checking journey status:", error.message);
        return res.status(500).json({ error: "Database error", details: error.message });
      }
      
      if (journeyStart?.length > 0 && journeyStart[0].journey_started === true) {
        return res.status(404).json({ error: "Journey has already started" });
      }

      const journeyError = await updateJourneyStarted(schedule_id);

      if (journeyError) {
          console.error("Error updating journey status:", journeyError.message);
          return res.status(500).json({ error: "Failed to update journey status", details: journeyError.message });
      }

      const { locationData: originData, locationError: originError } = await getLocationCoordinates(driver.pickup);
      if (originError) {
        return res.status(404).json({ error: "Origin location not found" });
      }

      const { locationData: destinationData, locationError: destinationError } = await getLocationCoordinates(driver.destination);
      if (destinationError) {
        return res.status(404).json({ error: "Destination location not found" });
      }
      
      const originCoords = `${originData.latitude},${originData.longitude}`;
      const destinationCoords = `${destinationData.latitude},${destinationData.longitude}`;

      const { polyline, duration } = await getOptimisedRoute(originCoords, destinationCoords);
      if (!polyline || !duration) {
          return res.status(404).json({ error: "No optimized route found." });
      }

      let activeDrivers = loadActiveDrivers();
      activeDrivers = activeDrivers.filter(d => d.driver_id !== driver_id);
      activeDrivers.push({ driver_id, schedule_id, polyline, currentLocation, destination: destinationCoords });
      saveActiveDrivers(activeDrivers);

      const decodedRoute = decodeRoute(polyline);

      res.json({
          duration: duration,
          polyline: polyline,
          decodedRoute: decodedRoute
      });

  } catch (error) {
      console.error("Internal Server Error:", error.message);
      res.status(500).json({ error: "Internal Server Error", details: error.message });
  }
});

/**
 * API to stop the journey for a driver
 * Deletes the journey from the database
 * Updates the schedule to mark it as deleted (delete_schedule = true)
 * Deletes all notifications for the driver
 * @param {string} driver_id - The driver's unique identifier
 * @param {string} schedule_id - The schedule's unique identifier
 * @returns {object} - Success message if the journey was stopped successfully
 */
app.post('/api/stop-journey', async (req, res) => {
  try {
      const { driver_id, schedule_id } = req.body;

      const schedule = await getStartJourneyDriver(driver_id, schedule_id);

      if (!schedule) {
          return res.status(404).json({ error: "Driver or route not found" });
      }

      const deleteJourneyError = await deleteJourney(schedule_id);

      if (deleteJourneyError) {
          console.error("Error deleting journey:", deleteJourneyError.message);
          return res.status(500).json({ error: "Failed to delete journey", details: deleteJourneyError.message });
      }

      const deleteScheduleError = await deleteSchedule(schedule_id);

      if (deleteScheduleError) {
          console.error("Error updating delete schedule:", deleteScheduleError.message);
          return res.status(500).json({ error: "Failed to update delete schedule", details: deleteScheduleError.message });
      }

      const deleteNotificationError = await deleteNotifcation(driver_id);

      if (deleteNotificationError) {
          console.error("Error deleting notifications:", deleteNotificationError.message);
          return res.status(500).json({ error: "Database error", details: deleteNotificationError.message });
      }

      let activeDrivers = loadActiveDrivers();
      activeDrivers = activeDrivers.filter(d => d.driver_id !== driver_id); 
      saveActiveDrivers(activeDrivers);

      res.json({ message: "Journey stopped successfully" });

  } catch (error) {
      console.error("Internal Server Error:", error.message);
      res.status(500).json({ error: "Internal Server Error", details: error.message });
  }
});


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
app.post('/api/notify-driver', async (req, res) => {
  const { driver_id, message, cameraId, timeStamp, seen } = req.body;

  if (!driver_id || !message || !cameraId) {
      return res.status(400).json({ error: "Missing notification parameters (driver_id, message, cameraId required)." });
  }

  console.log(`Notification received for Driver ${driver_id}: ${message}`);

  
  const { existingNotification, checkError } = await checkExistingNotification(driver_id, cameraId);

  if (checkError && checkError.code !== 'PGRST116') {
    console.error("Error checking existing notification:", checkError.message);
    return res.status(500).json({ error: "Error checking existing notification", details: checkError.message });
  }

  if (existingNotification) {
    return res.json({ success: false, message: "Notification already exists for this camera"});
  }

  const insertError = await insertNotification(driver_id, cameraId, message, timeStamp, seen);

  if (insertError) {
      console.error("Error inserting notification:", insertError.message);
      return res.status(500).json({ error: "Error inserting notification", details: insertError.message });
  }

  res.json({ success: true, message: "Notification added" });
  
});

app.post('/api/test-congestion', (req, res) => {
  const { cameraId } = req.body;
  triggerManualCongestion(cameraId);
  res.send({ status: 'Manual congestion triggered' });
});



app.listen(port, () => {
  console.log(`Bussin Buses Web Server listening at http://localhost:${port}`);
});