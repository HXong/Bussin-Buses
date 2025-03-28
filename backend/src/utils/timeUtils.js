function getSGTime(){
    const options = {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: true,
        timeZone: 'Asia/Singapore'
      };

    let sgTime = new Date().toLocaleString('en-SG', options);

    let [date, time] = sgTime.split(", ");
    let [month, day, year] = date.split("/");

    return `${day}/${month}/${year} ${time}`;
}

module.exports = { getSGTime };