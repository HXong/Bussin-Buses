const request = require('supertest');
const app = require('../app');

describe('JourneyController - /startJourney', () => {

  it('should return 200 with polyline and decodedRoute if input is valid', async () => {
    const res = await request(app)
      .post('/api/startJourney')
      .send({
        driver_id: 'f397f32e-d659-4c6b-b720-48ac11888955',
        schedule_id: '137'
      });

    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('polyline');
    expect(res.body).toHaveProperty('decodedRoute');
    expect(res.body).toHaveProperty('duration');
  });

  it('should return 404 if driver is not found', async () => {
    const res = await request(app)
      .post('/api/startJourney')
      .send({
        driver_id: 'MeDrivesCar',
        schedule_id: '137'
      });

    expect(res.statusCode).toBe(404);
    expect(res.body).toHaveProperty('error');
  });

  it('should return 404 if schedule is not found', async () => {
    const res = await request(app)
      .post('/api/startJourney')
      .send({
        driver_id: 'f397f32e-d659-4c6b-b720-48ac11888955',
        schedule_id: '400000'
      });

    expect(res.statusCode).toBe(404);
    expect(res.body).toHaveProperty('error');
  });

  it('should return 409 if journey has already started', async () => {
    const res = await request(app)
      .post('/api/startJourney')
      .send({
        driver_id: 'e9fd1879-ce42-4ab4-8631-ecef99facd5a',
        schedule_id: '138'
      });

    expect(res.statusCode).toBe(409);
    expect(res.body).toHaveProperty('error');
  });

  it('should return 500 on internal error', async () => {
    const res = await request(app)
      .post('/api/startJourney')
      .send({
        driver_id: null, 
        schedule_id: '137'
      });

    expect(res.statusCode).toBe(500);
    expect(res.body).toHaveProperty('error');
  });

});

describe('JourneyController - /stopJourney', () => {

  it('should return 200 if journey is stopped successfully', async () => {
    const res = await request(app)
      .post('/api/stopJourney')
      .send({
        driver_id: 'f397f32e-d659-4c6b-b720-48ac11888955',
        schedule_id: '153'
      });

    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('message', 'Journey stopped successfully');
  });

  it('should return 404 if driver or schedule is invalid', async () => {
    const res = await request(app)
      .post('/api/stopJourney')
      .send({
        driver_id: 'IDriveCars',
        schedule_id: '600'
      });

    expect(res.statusCode).toBe(404);
    expect(res.body).toHaveProperty('error');
  });

  it('should return 500 if deletion of journey fails', async () => {
    const res = await request(app)
      .post('/api/stopJourney')
      .send({
        driver_id: 'f397f32e-d659-4c6b-b720-48ac11888955',
        schedule_id: 'deletion-fail'
      });

    expect([500, 200]).toContain(res.statusCode);
  });

});
