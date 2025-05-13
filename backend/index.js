/**
 * This is the entry point of the backend application.
 * It sets up the Express server and configures the API routes.
 */
const express = require('express');
const app = express();
const router = require('./src/routes/index');

app.use(express.json());
app.use('/api', router);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));