const functions = require('@google-cloud/functions-framework');
functions.http('getUserProfile', (req, res) => {
  res.status(200).json({ id: "102938", name: "John Doe", profile: "Admin", email: "john@example.com" });
});
