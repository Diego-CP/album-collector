const express = require('express');
const authenticateToken = require('../../middleware/auth');
const recalculateTrades = require('../utils/recalculatetrades');
const router = express.Router();
router.use(authenticateToken);
const db = require('../db');

router.put('/update', async function(req, res) {
    try {
        const { updates } = req.body;

        if (!Array.isArray(updates) || updates.length === 0) {
            return res.status(400).json({ error: 'No updates provided.' });
        }

        for (const u of updates) {
            if (
                typeof u.sticker_id !== 'number' ||
                typeof u.needs !== 'boolean' ||
                typeof u.duplicates_amount !== 'number' ||
                u.duplicates_amount < 0
            ) {
                return res.status(400).json({ error: 'Invalid update payload.' });
            }
        }

        const stickerIds = updates.map(u => u.sticker_id);
        const [rows] = await db.query(
            `SELECT id FROM stickers WHERE id IN (?)`,
            [stickerIds]
        );
        if (rows.length !== stickerIds.length) {
            return res.status(400).json({ error: 'One or more sticker IDs are invalid.' });
        }

        const [userRows] = await db.query(
            `SELECT id FROM users WHERE cognito_sub = ?`,
            [req.user.sub]
        );
        if (!userRows.length) return res.status(401).json({ error: 'User not found.' });

        const userId = userRows[0].id;

        const values = updates.map(u => [userId, u.sticker_id, u.needs, u.duplicates_amount]);
        await db.query(
            `INSERT INTO collection (user_id, sticker_id, needs, duplicates_amount)
            VALUES ?
            ON DUPLICATE KEY UPDATE
                needs = VALUES(needs),
                duplicates_amount = VALUES(duplicates_amount)`,
            [values]
        );

        const [userGroups] = await db.query(
            `SELECT group_id FROM group_members WHERE user_id = ?`,
            [userId]
        );

        await Promise.all(userGroups.map(row => recalculateTrades(row.group_id)));

        res.json({ success: true });
    } catch(err) {
        console.error(err);
        res.status(500).json({ error: 'Something went wrong.' });
    }
});

module.exports = router;