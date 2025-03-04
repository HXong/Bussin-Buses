require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { getOptimisedRoute } = require('../services/routeHandler');
const fs = require('fs');
const path = require('path');

const app = express();
const port = process.env.PORT || 3000;

app.use(cors())
app.use(express.json());

const DRIVERS_FILE = path.join(__dirname, '../../active_drivers.json');
let activeDrivers = JSON.parse(fs.readFileSync(DRIVERS_FILE, 'utf8'));
let active_sessions = {};
let driverNotifications = {};

function saveActiveDrivers() {
  fs.writeFileSync(DRIVERS_FILE, JSON.stringify(activeDrivers, null, 2));
}

app.post('/api/login', (req, res) => {
  const { username, password } = req.body;
  const driver = activeDrivers.find(d => d.username === username && d.password === password);

  if (!driver) {
      return res.status(401).json({ error: "Invalid username or password" });
  }

  active_sessions[driver.driver_id] = driver; // Store active session
  res.json({ 
      driver_id: driver.driver_id, 
      username: driver.username, 
      currentLocation: driver.currentLocation 
  });
});

app.get('/api/scheduled-routes/:driverId', (req, res) => {
  const driverId = req.params.driverId;
  const driver = activeDrivers.find(d => d.driver_id === driverId);

  if (!driver) {
    return res.status(401).json({ error: "Invalid username or password" });
  }

  res.json({
    scheduled_route: driver.scheduled_route || []
  });
});

app.post('/api/update-driver', (req, res) => {
  const { driver_id, route_id, currentLocation, polyline } = req.body;

  let driver = activeDrivers.find(d => d.driver_id === driver_id);

  if (!driver) {
      return res.status(404).json({ error: "Driver not found" });
  }

  let route = driver.scheduled_route.find(r => r.route_id === route_id);

  if (!route) {
      return res.status(404).json({ error: "Route not found for this driver" });
  }

  route.polyline = polyline || route.polyline;
  route.origin = route.origin || currentLocation;
  driver.currentLocation = currentLocation; 
  saveActiveDrivers();

  res.json({ message: "Driver location updated", driver });
});

app.post('/api/logout', (req, res) => {
  const { driver_id } = req.body;
  
  if (active_sessions[driver_id]) {
      delete active_sessions[driver_id];
      return res.json({ message: "Logout successful" });
  }

  res.status(400).json({ error: "Driver not logged in" });
});

app.get('/api/get-next-route-id', (req, res) => {
  const driverId = req.query.driver_id;
  const driver = activeDrivers.find(d => d.driver_id === driverId);

  if (!driver) {
      return res.status(404).json({ error: "Driver not found" });
  }

  const existingRoutes = driver.scheduled_route.map(r => parseInt(r.route_id.substring(1))); 
  let nextId = 1;

  while (existingRoutes.includes(nextId) && nextId < 1000) {
      nextId++;
  }

  if (nextId >= 1000) {
      return res.status(400).json({ error: "No available route ID found." });
  }

  res.json({ next_route_id: `R${nextId.toString().padStart(3, '0')}` });
});

app.post('/api/add-route', (req, res) => {
  const { driver_id, route } = req.body;
  const driver = activeDrivers.find(d => d.driver_id === driver_id);

  if (!driver) {
      return res.status(404).json({ error: "Driver not found" });
  }

  driver.scheduled_route.push(route);
  saveActiveDrivers();

  res.json({ message: "Route added successfully", route });
});


app.post('/api/start-journey', (req, res) => {

  const { driver_id, route_id } = req.body;
  let driver = activeDrivers.find(d => d.driver_id === driver_id);
  if (!driver) return res.status(404).json({ error: "Driver not found" });
  driver.onRoute = true;

  let route = driver.scheduled_route.find(r => r.route_id === route_id);
  if (!route) return res.status(404).json({ error: "Route not found" });

  route.journey_started = true;
  saveActiveDrivers();
  res.json({ message: "Journey started" });

});

app.post('/api/stop-journey', (req, res) => {

  const { driver_id, route_id } = req.body;
  let driver = activeDrivers.find(d => d.driver_id === driver_id);
  if (!driver) return res.status(404).json({ error: "Driver not found" });
  driver.onRoute = false;

  driver.scheduled_route = driver.scheduled_route.filter(route => route.route_id !== route_id);
  driverNotifications[driver_id] = [];
  saveActiveDrivers();
  res.json({ message: "Journey stopped" });

});


app.get('/api/check-journey/:driver_id/:route_id', (req, res) => {

  const { driver_id, route_id } = req.params;

  let driver = activeDrivers.find(d => d.driver_id === driver_id);

  if (!driver) return res.status(404).json({ error: "Driver not found" });

  let route = driver.scheduled_route.find(r => r.route_id === route_id);
  if (!route) return res.json({ journey_started: false });

  res.json({ journey_started: route.journey_started });

});

app.get('/api/get-route', async(req, res) => {

  try{
    const { origin, destination } = req.query;

    if (!origin || !destination) {
        return res.status(400).json({ error: "Missing parameters: origin, destination required." });
    }

    const polyline = await getOptimisedRoute(origin, destination);
    if (!polyline) {
        return res.status(404).json({ error: "No route found." });
    }

    res.json({
        polyline: polyline
    });

  } catch (error){
    res.status(500).json({ error: 'Error fetching route data', details: error.message });
  }
});

app.post('/api/accept-reroute', async (req, res) => {
  try {
      const { origin, destination } = req.body;

      if (!origin || !destination) {
          return res.status(400).json({ error: "Missing parameters: origin and destination required." });
      }

      const optimizedRoute = await getOptimisedRoute(origin, destination, true);
      if (!optimizedRoute) {
          return res.status(404).json({ error: "No optimized route found." });
      }

      res.json({ polyline: optimizedRoute });

  } catch (error) {
      console.error("Error fetching optimized route:", error.message);
      res.status(500).json({ error: 'Internal server error', details: error.message });
  }
});

// API to Receive Notifications and Store them
app.post('/api/notify-driver', (req, res) => {
  const { driver_id, message, cameraId } = req.body;

  if (!driver_id || !message || !cameraId) {
      return res.status(400).json({ error: "Missing notification parameters (driver_id, message, cameraId required)." });
  }

  console.log(`Notification received for Driver ${driver_id}: ${message}`);

  if (!driverNotifications[driver_id]) {
      driverNotifications[driver_id] = [];
  }

  const existingNotification = driverNotifications[driver_id].find(n => n.cameraId === cameraId);
  if (!existingNotification) {
      driverNotifications[driver_id].push({ message, cameraId, timestamp: new Date().toISOString() });
      res.json({ success: true, message: "Notification added" });
  } else {
      res.json({ success: false, message: "Notification already exists for this camera" });
  }
});

// API to Fetch Notifications for a Driver (For Frontend)
app.get('/api/get-notifications/:driverId', (req, res) => {
  const driverId = req.params.driverId;
  const notifications = driverNotifications[driverId] || [];

  if (notifications.length > 0) {
    res.json({ notifications });  
  } else {
    res.json({ notifications: [] });
  }
});

app.listen(port, () => {
  console.log(`Bussin Buses Web Server listening at http://localhost:${port}`);
});