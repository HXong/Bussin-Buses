const { supabase } = require("../model/supabaseClient");

/**
 * Updates the ETA (in minutes) for a given schedule_id
 * @param {number} schedule_id 
 * @param {number} eta 
 * @returns error if any
 */
async function updateScheduleETA(schedule_id, eta) {
    const { error } = await supabase
        .from('schedules')
        .update({ eta: eta })
        .eq('schedule_id', schedule_id);

    return error;
}

/**
 * Fetches the driver's data from the supabase
 * @param {string} driver_id 
 * @param {string} schedule_id 
 * @returns driver data and error
 */
async function getStartJourneyDriver(driver_id, schedule_id){
    const { data: driver, error: driverError } = await supabase
        .from('schedules')
        .select('*')
        .eq('driver_id', driver_id)
        .eq('schedule_id', schedule_id)
        .eq('delete_schedule', false)
        .single();

    return {driver, driverError};
}

/**
 * Checks whether the journey has started
 * fetches the journey started status from the supabase
 * @param {string} schedule_id 
 * @returns journey started status and error
 */
async function hasJourneyStarted(schedule_id){
    const { data: journeyStart, error } = await supabase
            .from('journey')
            .select('journey_started')
            .eq('schedule_id', schedule_id)
    
    return {journeyStart, error};
}

/**
 * Updates the journey started status in the supabase
 * @param {string} schedule_id 
 * @returns journey error
 */
async function updateJourneyStarted(schedule_id) {
    const { error: journeyError } = await supabase
          .from('journey')
          .update({ journey_started: true })
          .eq('schedule_id', schedule_id);

    return journeyError;
}

/**
 * gettting the location coordinates from the supabase
 * @param {object} location_id 
 * @returns location coordinates and error
 */
async function getLocationCoordinates(location_id){
    const { data, error } = await supabase
        .from('location')
        .select('latitude, longitude')
        .eq('location_id', location_id)
        .single();
    
    if (error || !data) {
        return { locationData: null, locationError: error || new Error('Location not found') };
    }

    return { locationData: data, locationError: null };
}

/**
 * @description get the driver location from the supabase
 * @param {String} driver_id 
 * @returns driver location and error
 */
async function getDriverLocation(driver_id){
    const { data, error } = await supabase
        .from('driver_location')
        .select('latitude, longitude')
        .eq('driver_id', driver_id)
        .single();

    if (error || !data) {
        return { driverLocation: null, driverError: error || new Error('Driver not found') };
    }

    return { driverLocation: data, driverError: null };
}

/**
 * Checks whether the notification exists in the supabase
 * @param {string} driver_id 
 * @param {object} cameraId 
 * @returns existing notification and error
 */
async function checkExistingNotification(driver_id, cameraId){
    const { data: existingNotification, error: checkError } = await supabase
          .from('notifications')
          .select('*')
          .eq('driver_id', driver_id)
          .eq('camera_id', cameraId)
          .single();
    
    return {existingNotification, checkError};
}

/**
 * inserts the notification in the supabase
 * @param {string} driver_id 
 * @param {object} cameraId 
 * @param {string} message 
 * @param {string} timeStamp 
 * @param {object} seen 
 * @returns insert error
 */
async function insertNotification(driver_id, cameraId, message, timeStamp, seen){
    const { error: insertError } = await supabase
      .from('notifications')
      .insert([{ 
          driver_id: driver_id,
          camera_id: cameraId,
          message: message,
          timestamp: timeStamp,
          seen: seen
      }]);
    
    return insertError;
}

/**
 * deletes the journey from the supabase
 * @param {string} schedule_id 
 * @returns delete journey error
 */
async function deleteJourney(schedule_id){
    const { error: deleteJourneyError } = await supabase
          .from('journey')
          .delete()
          .eq('schedule_id', schedule_id);
    
    return deleteJourneyError;
}

/**
 * updates the schedule in the supabase of delete_schedule to true
 * @param {string} schedule_id 
 * @returns delete schedule error
 */
async function deleteSchedule(schedule_id){
    const { error: deleteScheduleError } = await supabase
          .from('schedules')
          .update({ delete_schedule: true })
          .eq('schedule_id', schedule_id);
    
    return deleteScheduleError;
}

async function deleteCommuterBookings(schedule_id){
    const { error: deleteCommuterBookingsError } = await supabase
        .from('bookings')
        .delete()
        .eq('schedule_id', schedule_id);
    
    return deleteCommuterBookingsError;
}

/**
 * deletes the notification from the supabase
 * @param {string} driver_id 
 * @returns delete notification error
 */
async function deleteNotifcation(driver_id){
    const { error: deleteNotificationError } = await supabase
          .from('notifications')
          .delete()
          .eq('driver_id', driver_id);
    
    return deleteNotificationError;
}

module.exports = {
    getStartJourneyDriver,
    hasJourneyStarted,
    updateJourneyStarted,
    getLocationCoordinates,
    getDriverLocation,
    deleteJourney,
    deleteSchedule,
    deleteCommuterBookings,
    deleteNotifcation,
    checkExistingNotification,
    insertNotification,
    updateScheduleETA
};