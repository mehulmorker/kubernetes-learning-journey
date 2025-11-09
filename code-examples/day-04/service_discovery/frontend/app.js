// frontend-app.js
const express = require('express');
const axios = require('axios');
const app = express();
const PORT = 3000;

app.get('/', async (req, res) => {
  try {
    // Call backend using Service DNS name!
    const response = await axios.get('http://backend-service:80');
    res.json({
      message: 'Frontend calling backend',
      backendResponse: response.data
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(PORT, () => {
  console.log(`Frontend running on port ${PORT}`);
});