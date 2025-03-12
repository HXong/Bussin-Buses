const express = require('express');
const path = require('path');

const app = express();
const PORT = 3001;

app.use(express.static(path.join(__dirname, "../../sample_frontend")));

app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, '../../sample_frontend', 'login.html'));
});

app.get('/menu', (req, res) => {
    res.sendFile(path.join(__dirname, '../../sample_frontend', 'menu.html'));
});

app.get('/create_route', (req, res) => {
    res.sendFile(path.join(__dirname, '../../sample_frontned', 'create_route.html'));
});

app.get('/route-selection', (req, res) => {
    res.sendFile(path.join(__dirname, '../../sample_frontend', 'route_selection.html'));
});

app.get('/map', (req, res) => {
    res.sendFile(path.join(__dirname, '../../sample_frontend', 'map.html'));
});


app.listen(PORT, () => {
    console.log(`Frontend Server running at http://localhost:${PORT}`);
});