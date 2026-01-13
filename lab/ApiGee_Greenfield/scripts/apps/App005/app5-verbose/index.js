const express = require('express');
const app = express();
app.get('/', (req, res) => {
    throw new Error("Database query failed: connect ECONNREFUSED 10.2.4.5:5432");
});
app.use((err, req, res, next) => {
    res.status(500).send({ error: "Internal Server Error", message: err.message, stack: err.stack });
});
app.listen(8080);
