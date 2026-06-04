const express = require('express');
const authenticateToken = require('../../middleware/auth');
const router = express.Router();
router.use(authenticateToken);

router.post('/create', async function(req, res) {
    try {
        let { name } = req.body;

        // Sanitize
        name = name.trim();
        if (!name || name.length > 100) {
            return res.status(400).json({ error: "Invalid group name." });
        }

        const [rows] = await db.execute(
            'SELECT id FROM users WHERE cognito_sub = ?',
            [req.user.sub]
        );
        const userId = rows[0].id;

        let result;
        let attempts = 0;
        const MAX_ATTEMPTS = 5;

        while (attempts < MAX_ATTEMPTS) {
            try {
                const inviteCode = generateRandomCode(); // TODO: Implement generate random code function
                [result] = await db.execute(
                    "INSERT INTO user_groups (name, invite_code, created_by_user_id) VALUES (?, ?, ?)",
                    [name, inviteCode, userId]
                );
                break;
            } catch (err) {
                if (err.code === 'ER_DUP_ENTRY') {
                    attempts++;
                    if (attempts === MAX_ATTEMPTS) {
                        return res.status(500).json({ error: 'Could not generate a unique invite code, please try again.' });
                    }
                } else {
                    throw err;
                }
            }
        }

        // TODO: result.insertId will return the ID of the group, so we could reroute to the group's page once it is created
        res.json({ success: true, id: result.insertId });

    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Something went wrong.' });
    }
});

router.post('/join', async function(req, res){
    res.json({ id: 1, name: "testname"});
    /*
    try {
        let { code } = req.body;

        // Sanitize
        code = code.trim();
        if (!code || code.length > 10) {
            return res.status(400).json({ error: "Invalid group code." });
        }

        // Find the group
        const [rows] = await db.execute(
            'SELECT id FROM user_groups WHERE invite_code = ?',
            [code]
        );

        if (rows.length === 0) {
            return res.status(404).json({ error: 'Group not found.' });
        }

        const groupId = rows[0].id;

        // Check if user is already a member
        const [existing] = await db.execute(
            'SELECT id FROM group_members WHERE group_id = ? AND user_id = ?',
            [groupId, req.user.id]
        );

        if (existing.length > 0) {
            return res.status(409).json({ error: 'You are already a member of this group.' });
        }

        // Add the member
        await db.execute(
            'INSERT INTO group_members (group_id, user_id, role) VALUES (?, ?, "member")',
            [groupId, req.user.id]
        );

        res.json({ success: true });

    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Something went wrong.' });
    }
    */
});

module.exports = router;