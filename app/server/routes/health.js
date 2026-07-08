const express = require('express');
const router = express.Router();
const db = require('../db');

router.get('/live', (req, res) => {
    res.sendStatus(200);
});

router.get('/ready', async (req, res) => {
    try {
        await db.execute('SELECT 1');
        res.sendStatus(200);
    } catch {
        res.sendStatus(503);
    }
});

module.exports = router;