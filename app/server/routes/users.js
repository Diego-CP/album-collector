const express = require('express');
const authenticateToken = require('../../middleware/auth');
const router = express.Router();
router.use(authenticateToken);
const db = require('../db');

router.post('/changeusername', async function(req, res) {
    try {
        let { name: username } = req.body;
        console.log("USERNAME: " + username);

        // Sanitize
        username = username.trim();
        if (!username || username.length > 100) {
            return res.status(400).json({ error: "Invalid username." });
        }

        const [rows] = await db.execute(
            'SELECT id FROM users WHERE cognito_sub = ?',
            [req.user.sub]
        );
        const userId = rows[0].id;

        // TODO: Limit username updates to one every 24 hours

        // Change the username
        await db.execute(
            'UPDATE users SET display_name = ? WHERE id = ?',
            [username, userId]
        );

        res.json({ success: true });

    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Something went wrong.' });
    }
});

module.exports = router;