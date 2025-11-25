const express = require('express');
const app = express();
const port = process.env.PORT || 8080;

app.use(express.json());

// Endpoint to simulate backend processing
app.get('/api/data', (req, res) => {
    const { id } = req.query;

    if (!id || isNaN(id)) {
        // Deliberately throwing an error to simulate backend failure and leak stack trace
        throw new Error(`Invalid parameter 'id': expected a number but received '${id}'. Database query failed.`);
    }

    res.json({ success: true, data: { id, message: "Data fetched successfully" } });
});

// Error handling middleware that leaks stack trace
app.use((err, req, res, next) => {
    // Returns 500 but includes the full error stack in the response (security vulnerability)
    res.status(500).send({
        error: "Internal Server Error",
        message: err.message,
        stack: err.stack
    });
});

app.listen(port, () => {
    console.log(`Vulnerable backend listening on port ${port}`);
});
