const supabase = require("../config/supabaseClient");

async function getStartJourneyDriver(driver_id, schedule_id){
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

    return driver;
}

