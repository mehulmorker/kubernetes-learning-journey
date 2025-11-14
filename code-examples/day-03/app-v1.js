// Node.js app v1
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.json({ 
    message: 'Hello from Kubernetes!',
    hostname: require('os').hostname(),
    timestamp: new Date().toISOString()
  });
});

app.listen(port, () => {
  console.log(`App listening on port ${port}`);
});

