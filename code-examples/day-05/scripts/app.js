// app.js
const express = require("express");
const app = express();

// Read from environment variables
const PORT = process.env.PORT || 3000;
const LOG_LEVEL = process.env.LOG_LEVEL || "info";
const NODE_ENV = process.env.NODE_ENV || "development";
const FEATURE_NEW_UI = process.env.FEATURE_NEW_UI === "true";

app.get("/", (req, res) => {
  res.json({
    message: "ConfigMap Demo",
    config: {
      port: PORT,
      logLevel: LOG_LEVEL,
      environment: NODE_ENV,
      featureNewUI: FEATURE_NEW_UI,
    },
    hostname: require("os").hostname(),
  });
});

app.get("/health", (req, res) => {
  res.status(200).json({ status: "healthy" });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT} in ${NODE_ENV} mode`);
});
