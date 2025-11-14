// Node.js app v3
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.json({ 
    message: "Version 3",
    version: "3.0.0",
    hostname: require('os').hostname(),
    timestamp: new Date().toISOString()
  });
});

app.listen(port, () => {
  console.log(`App v3 listening on port ${port}`);
});

