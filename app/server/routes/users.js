const express = require('express');
const authenticateToken = require('../../middleware/auth');
const router = express.Router();
router.use(authenticateToken);
const db = require('../db');

router.post('/changeusername', async function(req, res) {
    try {
        let { name: username } = req.body;

        // Sanitize
        username = username.trim();
        if (!username || username.length < 2 || username.length > 20) {
            return res.status(400).json({ error: "Invalid username." });
        }

        // TODO: Limit username updates to one every 24 hours

        await db.execute(
            'UPDATE users SET display_name = ? WHERE cognito_sub = ?',
            [username, req.user.sub]
        );

        res.json({ success: true });

    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Something went wrong.' });
    }
});

router.get('/getusername', async function(req, res) {
    try {
        const [[user]] = await db.execute(
            'SELECT display_name FROM users WHERE cognito_sub = ?', 
            [req.user.sub]
        );

        if (!user) return res.status(404).json({ error: 'User not found.' });

        res.json({ username: user.display_name });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Something went wrong.' });
    }
});

module.exports = router;