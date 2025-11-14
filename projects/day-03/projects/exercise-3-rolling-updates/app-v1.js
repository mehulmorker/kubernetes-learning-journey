// Node.js app v1
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.json({ 
    message: "Version 1",
    version: "1.0.0",
    hostname: require('os').hostname(),
    timestamp: new Date().toISOString()
  });
});

app.listen(port, () => {
  console.log(`App v1 listening on port ${port}`);
});

