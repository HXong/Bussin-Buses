require('dotenv').config();
const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const { decode } = require('@here/flexpolyline');
const { supabase } = require('../config/supabaseClient');
const { getOptimisedRoute } = require('../services/routeHandler');

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

function decodeRoute(encodedPolyline){
  try {
    const decoded = decode(encodedPolyline).polyline; 
    return decoded;
  } catch (error) {
      console.error("Error decoding route:", error.message);
      return null;
  }
}

async function getNextScheduleID() {
  const { data: schedules, error } = await supabase
      .from('schedules')
      .select('schedule_id')
      .order('schedule_id', { ascending: true });

  if (error) {
      console.error("Error fetching schedules:", error.message);
      return null;
  }

  if (!schedules || schedules.length === 0) return 1;

  let nextID = 1;
  for (const row of schedules) {
      if (row.schedule_id !== nextID) {
          return nextID; 
      }
      nextID++;
  }
  return nextID; 
}

app.post('/api/confirm-route', async (req, res) => {
  try {
      const { driver_id, pickup, destination, date, time } = req.body;

      if (!driver_id || !pickup || !destination) {
          return res.status(400).json({ error: "Missing required fields: driver_id, origin, destination" });
      }

      const schedule_id = await getNextScheduleID();

      const { error: scheduleError } = await supabase
          .from('schedules')
          .insert([
              {
                  schedule_id,
                  driver_id,
                  pickup,
                  destination,
                  date,
                  time
              }
          ]);

      if (scheduleError) throw scheduleError;

      const { error: journeyError } = await supabase
          .from('journey')
          .insert([{ schedule_id, journey_started: false }]);

      if (journeyError) throw journeyError;

      res.json({
          message: "Route added successfully",
          newRoute: { schedule_id, driver_id, pickup, destination, journey_started: false }
      });

  } catch (error) {
      console.error("Error confirming route:", error.message);
      res.status(500).json({ error: "Internal Server Error", details: error.message });
  }
});

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

//API to call for new route after recieving congestion notification
app.get('/api/get-reroute', async(req, res) => {

  try{
    const { driverId } = req.query;

    if (!driverId) {
        return res.status(400).json({ error: "Missing parameters: driver id required." });
    }

    const activeDrivers = loadActiveDrivers();
    const driver = activeDrivers.find(d => d.driver_id === driverId);
    const [driverLatitude, driverLongitude] = driver.currentLocation;


    const originCoords = `${driverLatitude},${driverLongitude}`;
    const destinationCoords = driver.destinationCoords;

    console.log(`Resolved Coordinates: Origin(${originCoords}) → Destination(${destinationCoords})`);

    const polyline = await getOptimisedRoute(originCoords, destinationCoords);
    if (!polyline) {
        return res.status(404).json({ error: "No route found." });
    }

    driver.polyline = polyline;
    saveActiveDrivers(driver);

    const decodedRoute = decodeRoute(polyline);

    res.json({
        polyline: polyline,
        decodedRoute: decodedRoute
    });

  } catch (error){
    res.status(500).json({ error: 'Error fetching route data', details: error.message });
  }
});

app.post('/api/start-journey', async (req, res) => {
  try {
      const { driver_id, schedule_id } = req.body;
      const currentLocation = [1.335128, 103.937533];
    
      //getStartJourneyDriver
      const { data: driver, error: driverError } = await supabase
          .from('schedules')
          .select('*')
          .eq('driver_id', driver_id)
          .eq('schedule_id', schedule_id)
          .eq('delete_schedule', false)
          .single();

      if (driverError || !driver) {
          return res.status(404).json({ error: "Driver or route not found" });
      }

      const { data: journeyStart, error } = await supabase
            .from('journey')
            .select('journey_started')
            .eq('schedule_id', schedule_id)
        
        if (error) {
            return res.status(500).json({ error: "Database error", details: error.message });
        }
    
        if (journeyStart?.length > 0 && journeyStart[0].journey_started === true) {
            return res.status(404).json({ error: "Journey has already started" });
        }

      const { error: journeyError } = await supabase
          .from('journey')
          .update({ journey_started: true })
          .eq('schedule_id', schedule_id);

      if (journeyError) {
          console.error("Error updating journey status:", journeyError.message);
          return res.status(500).json({ error: "Failed to update journey status", details: journeyError.message });
      }

      const { data: originData, error: originError } = await supabase
        .from('location')
        .select('latitude, longitude')
        .eq('location_id', driver.pickup)
        .single();

    if (originError || !originData) {
        return res.status(404).json({ error: "Origin location not found" });
    }

      const { data: destinationData, error: destinationError } = await supabase
        .from('location')
        .select('latitude, longitude')
        .eq('location_id', driver.destination)
        .single();

    if (destinationError || !destinationData) {
        return res.status(404).json({ error: "Destination location not found" });
    }

    const originCoords = `${originData.latitude},${originData.longitude}`;
    const destinationCoords = `${destinationData.latitude},${destinationData.longitude}`;

      const polyline = await getOptimisedRoute(originCoords, destinationCoords);
      if (!polyline) {
          return res.status(404).json({ error: "No optimized route found." });
      }

      let activeDrivers = loadActiveDrivers();
      activeDrivers = activeDrivers.filter(d => d.driver_id !== driver_id);
      activeDrivers.push({ driver_id, schedule_id, polyline, currentLocation, destination: destinationCoords });
      saveActiveDrivers(activeDrivers);

      const decodedRoute = decodeRoute(polyline);

      res.json({
          polyline: polyline,
          decodedRoute: decodedRoute
      });

  } catch (error) {
      console.error("Internal Server Error:", error.message);
      res.status(500).json({ error: "Internal Server Error", details: error.message });
  }
});


app.post('/api/stop-journey', async (req, res) => {
  try {
      const { driver_id, schedule_id } = req.body;

      const { data: schedule, error: scheduleError } = await supabase
          .from('schedules')
          .select('*')
          .eq('driver_id', driver_id)
          .eq('schedule_id', schedule_id)
          .single();

      if (scheduleError || !schedule) {
          return res.status(404).json({ error: "Schedule not found for this driver" });
      }

      const { error: deleteJourneyError } = await supabase
          .from('journey')
          .delete()
          .eq('schedule_id', schedule_id);

      if (deleteJourneyError) {
          console.error("Error deleting journey:", deleteJourneyError.message);
          return res.status(500).json({ error: "Failed to delete journey", details: deleteJourneyError.message });
      }

      const { error: deleteScheduleError } = await supabase
          .from('schedules')
          .update({ delete_schedule: true })
          .eq('schedule_id', schedule_id);

      if (deleteScheduleError) {
          console.error("Error updating delete schedule:", deleteScheduleError.message);
          return res.status(500).json({ error: "Failed to update delete schedule", details: deleteScheduleError.message });
      }

      const { error: deleteNotificationError } = await supabase
          .from('notifications')
          .delete()
          .eq('driver_id', driver_id);

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

app.post('/api/update-driver-location', (req, res) => {
    try {
        const { driver_id, latitude, longitude } = req.body;

        if (!driver_id || latitude === undefined || longitude === undefined) {
            return res.status(400).json({ error: "Missing driver_id, latitude, or longitude" });
        }

        let activeDrivers = loadActiveDrivers();
        let driver = activeDrivers.find(d => d.driver_id === driver_id);
        if (!driver) {
            return res.status(404).json({ error: "Driver not found in active sessions" });
        }

        driver.currentLocation = [latitude, longitude];

        saveActiveDrivers(activeDrivers);

        res.json({ message: "Driver location updated" });
    } catch (error) {
        console.error("Error updating driver location:", error.message);
        res.status(500).json({ error: "Internal server error" });
    }
});


app.get('/api/check-journey/:schedule_id', async (req, res) => {

  try{
    const { schedule_id } = req.params;

    const { data: journeyData, error } = await supabase
        .from('journey')
        .select('journey_started')
        .eq('schedule_id', schedule_id)
        .single();

    if (error) {
        console.error("Error fetching journey status:", error.message);
        return res.status(500).json({ error: "Internal Server Error", details: error.message });
    }

    if (!journeyData) {
        return res.json({ journey_started: false });
    }

    res.json({ journey_started: journeyData.journey_started });

  } catch (error) {

    console.error("Error checking journey:", error.message);
    res.status(500).json({ error: "Internal Server Error", details: error.message });

  }

});

// API to Receive Notifications and Store them
app.post('/api/notify-driver', async (req, res) => {
  const { driver_id, message, cameraId, timeStamp, seen } = req.body;

  if (!driver_id || !message || !cameraId) {
      return res.status(400).json({ error: "Missing notification parameters (driver_id, message, cameraId required)." });
  }

  console.log(`Notification received for Driver ${driver_id}: ${message}`);

  
  const { data: existingNotification, error: checkError } = await supabase
          .from('notifications')
          .select('*')
          .eq('driver_id', driver_id)
          .eq('camera_id', cameraId)
          .single();
  
  if (checkError && checkError.code !== 'PGRST116') {
      console.error("Error checking existing notification:", checkError.message);
      return res.status(500).json({ error: "Error checking existing notification", details: checkError.message });
  }

  if (existingNotification) {
      return res.json({ success: false, message: "Notification already exists for this camera" });
  }

  const { error: insertError } = await supabase
      .from('notifications')
      .insert([{ 
          driver_id: driver_id,
          camera_id: cameraId,
          message: message,
          timestamp: timeStamp,
          seen: seen
      }]);

  if (insertError) {
      console.error("Error inserting notification:", insertError.message);
      return res.status(500).json({ error: "Error inserting notification", details: insertError.message });
  }

  res.json({ success: true, message: "Notification added" });
  
});


app.listen(port, () => {
  console.log(`Bussin Buses Web Server listening at http://localhost:${port}`);
});