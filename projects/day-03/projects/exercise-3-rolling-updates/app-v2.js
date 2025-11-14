// Node.js app v2
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.json({ 
    message: "Version 2",
    version: "2.0.0",
    hostname: require('os').hostname(),
    timestamp: new Date().toISOString()
  });
});

app.listen(port, () => {
  console.log(`App v2 listening on port ${port}`);
});

