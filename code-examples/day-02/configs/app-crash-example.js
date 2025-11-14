// Add this at the top of app.js
if (process.env.CRASH === 'true') {
  throw new Error('Intentional crash!');
}

