const {
    getStartJourneyDriver,
    hasJourneyStarted,
    getLocationCoordinates,
    updateJourneyStarted,
    deleteJourney,
    deleteCommuterBookings,
    deleteSchedule,
    deleteNotifcation,
    updateScheduleETA
  } = require('../services/supabaseService');
  
const { getOptimisedRoute, decodeRoute } = require('../services/routeService');
const { updateActiveDriver, removeActiveDriver } = require('../services/activeDriverService');

/**
 * @description Start a journey for a driver. 
 * Get the optimized route and update the driver's active status
 * Retrieve the estimated time of arrival (ETA) for the journey
 * Update the schedule with the ETA
 * @param {String} driver_id
 * @param {String} schedule_id 
 * @returns polyline, duration, decodedRoute
 */
exports.startJourney = async (req, res) => {
  try {
    const { driver_id, schedule_id } = req.body;

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

    const currentLocation = [originData.latitude, originData.longitude];

    const originCoords = `${originData.latitude},${originData.longitude}`;
    const destinationCoords = `${destinationData.latitude},${destinationData.longitude}`;

    const { polyline, duration } = await getOptimisedRoute(originCoords, destinationCoords);
    if (!polyline || !duration) {
      return res.status(404).json({ error: "No optimized route found" });
    }

    updateActiveDriver(driver_id, schedule_id, polyline, currentLocation, destinationCoords);

    const decodedRoute = decodeRoute(polyline);

    const etaInMinutes = Math.ceil(duration / 60);

    const updateError = await updateScheduleETA(schedule_id, etaInMinutes);
    if (updateError) {
        throw updateError;
    }

    return res.json({ duration, polyline, decodedRoute });

  } catch (error) {
    console.error("Start journey error:", error.message);
    return res.status(500).json({ error: "Internal Server Error", details: error.message });
  }
};

/**
 * @description stop a journey for a driver.
 * Delete the journey from the database
 * Update the schedule to mark it as deleted (delete_schedule = true)
 * Delete all notifications for the driver
 * @param {String} driver_id
 * @param {String} schedule_id 
 * @returns success message
 */
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

    const deleteCommuterBookingsError = await deleteCommuterBookings(schedule_id);
    if(deleteCommuterBookingsError){
      return res.status(500).json({ error: "Failed to delete commuter bookings", details: deleteCommuterBookingsError.message });
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
  