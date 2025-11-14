const express = require("express");
const app = express();
const PORT = process.env.PORT || 3000;

app.get("/", (req, res) => {
  res.json({
    message: "Hello from Kubernetes!",
    hostname: require("os").hostname(),
    timestamp: new Date().toISOString(),
  });
});

app.get("/health", (req, res) => {
  res.status(200).json({ status: "healthy" });
});

app.get("/version", (req, res) => {
  res.json({ version: "1.0.0" });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
