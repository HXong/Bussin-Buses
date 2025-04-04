const {
    getStartJourneyDriver,
    hasJourneyStarted,
    getLocationCoordinates,
    updateJourneyStarted,
    deleteJourney,
    deleteSchedule,
    deleteNotifcation
  } = require('../services/supabaseService');
  
const { getOptimisedRoute, decodeRoute } = require('../services/routeService');
const { updateActiveDriver, removeActiveDriver } = require('../services/activeDriverService');
  
  exports.startJourney = async (req, res) => {
    try {
      const { driver_id, schedule_id } = req.body;
      const currentLocation = [1.335128, 103.937533];
  
      const { driver, driverError } = await getStartJourneyDriver(driver_id, schedule_id);
      if (!driver || driverError) {
        return res.status(404).json({ error: "Driver or route not found" });
      }
  
      const { journeyStart, error } = await hasJourneyStarted(schedule_id);
      if (journeyStart?.length > 0 && journeyStart[0].journey_started === true) {
        return res.status(409).json({ error: "Journey has already started" });
      }
  
      const journeyError = await updateJourneyStarted(schedule_id);
      if (journeyError) {
        return res.status(500).json({ error: "Failed to update journey status", details: journeyError.message });
      }
  
      const { locationData: originData, locationError: originError } = await getLocationCoordinates(driver.pickup);
      if (originError) return res.status(404).json({ error: "Origin not found" });
  
      const { locationData: destinationData, locationError: destinationError } = await getLocationCoordinates(driver.destination);
      if (destinationError) return res.status(404).json({ error: "Destination not found" });
  
      const originCoords = `${originData.latitude},${originData.longitude}`;
      const destinationCoords = `${destinationData.latitude},${destinationData.longitude}`;
  
      const { polyline, duration } = await getOptimisedRoute(originCoords, destinationCoords);
      if (!polyline || !duration) {
        return res.status(404).json({ error: "No optimized route found" });
      }
  
      updateActiveDriver(driver_id, schedule_id, polyline, currentLocation, destinationCoords);
  
      const decodedRoute = decodeRoute(polyline);
  
      return res.json({ duration, polyline, decodedRoute });
  
    } catch (error) {
      console.error("Start journey error:", error.message);
      return res.status(500).json({ error: "Internal Server Error", details: error.message });
    }
  };
  
  exports.stopJourney = async (req, res) => {
    try {
      const { driver_id, schedule_id } = req.body;
  
      const schedule = await getStartJourneyDriver(driver_id, schedule_id);
      if (!schedule) {
        return res.status(404).json({ error: "Driver or route not found" });
      }
  
      const deleteJourneyError = await deleteJourney(schedule_id);
      if (deleteJourneyError) {
        return res.status(500).json({ error: "Failed to delete journey", details: deleteJourneyError.message });
      }
  
      const deleteScheduleError = await deleteSchedule(schedule_id);
      if (deleteScheduleError) {
        return res.status(500).json({ error: "Failed to update delete schedule", details: deleteScheduleError.message });
      }
  
      const deleteNotificationError = await deleteNotifcation(driver_id);
      if (deleteNotificationError) {
        return res.status(500).json({ error: "Failed to delete notifications", details: deleteNotificationError.message });
      }
  
      removeActiveDriver(driver_id);
  
      return res.json({ message: "Journey stopped successfully" });
  
    } catch (error) {
      console.error("Stop journey error:", error.message);
      return res.status(500).json({ error: "Internal Server Error", details: error.message });
    }
  };
  