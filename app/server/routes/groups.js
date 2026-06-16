const express = require('express');
const authenticateToken = require('../../middleware/auth');
const router = express.Router();
router.use(authenticateToken);
const db = require('../db');

function generateRandomCode() {
    var code = '';
    var characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    var charactersLength = characters.length;
    for ( var i = 0; i < 7; i++ ) {
        code += characters.charAt(Math.floor(Math.random() * charactersLength));
    }
    return code;
}

router.post('/create', async function(req, res) {
    try {
        let { name } = req.body;

        // Sanitize
        name = name.trim();
        if (!name || name.length > 20 || name.length < 2) {
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
        const connection = await db.getConnection();
        await connection.beginTransaction();

        while (attempts < MAX_ATTEMPTS) {
            try {
                const inviteCode = generateRandomCode();
                [result] = await connection.execute(
                    "INSERT INTO user_groups (name, invite_code, created_by_user_id) VALUES (?, ?, ?)",
                    [name, inviteCode, userId]
                );

                await connection.execute(
                    "INSERT INTO group_members (group_id, user_id, role) VALUES (?, ?, 'admin')",
                    [result.insertId, userId]
                );

                await connection.commit();
                break;
            } catch (err) {
                await connection.rollback();
                if (err.code === 'ER_DUP_ENTRY') {
                    attempts++;
                    if (attempts === MAX_ATTEMPTS) {
                        return res.status(500).json({ error: 'Could not generate a unique invite code, please try again.' });
                    }
                } else {
                    throw err;
                }
            } finally {
                connection.release();
            }
        }

        res.json({ groupId: result.insertId});

    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Something went wrong.' });
    }
});

router.post('/join', async function(req, res){
    try {
        let { code } = req.body;

        // Sanitize
        code = code.trim();
        if (!code || code.length !== 7) {
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

        const [result] = await db.execute(
            `INSERT IGNORE INTO group_members (group_id, user_id, role)
            SELECT ?, id, 'member' FROM users WHERE cognito_sub = ?`,
            [groupId, req.user.sub]
        );

        if (result.affectedRows === 0) {
            return res.status(409).json({ error: 'You are already a member of this group.' });
        }

        res.json({ groupId });

    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Something went wrong.' });
    }
});

router.delete('/:groupId/leave', async function(req, res) {
    const { groupId } = req.params;

    const [result] = await db.execute(
        `DELETE FROM group_members
        WHERE group_id = ? AND user_id = (SELECT id FROM users WHERE cognito_sub = ?)`,
        [groupId, req.user.sub]
    );

    if (result.affectedRows === 0) return res.status(404).json({ error: 'You are not a member of this group.' });

    res.json({ success: true });
});

router.delete('/:groupId/delete', async function(req, res) {
    const { groupId } = req.params;

    const [result] = await db.execute(
        `DELETE ug FROM user_groups ug
         JOIN group_members gm ON ug.id = gm.group_id
         JOIN users u ON gm.user_id = u.id
         WHERE ug.id = ? AND u.cognito_sub = ? AND gm.role = 'admin'`,
        [groupId, req.user.sub]
    );

    if (result.affectedRows === 0) return res.status(403).json({ error: 'You are not an admin of this group.' });

    res.json({ success: true });
});

router.delete('/:groupId/remove/:userId', async function(req, res) {
    const { groupId, userId } = req.params;

    const [isAdmin] = await db.execute(
        `SELECT 1 FROM group_members gm
         JOIN users u ON gm.user_id = u.id
         WHERE gm.group_id = ? AND u.cognito_sub = ? AND gm.role = 'admin'`,
        [groupId, req.user.sub]
    );

    if (!isAdmin.length) return res.status(403).json({ error: 'You are not an admin of this group.' });

    const [result] = await db.execute(
        `DELETE FROM group_members WHERE group_id = ? AND user_id = ? AND role != 'admin'`,
        [groupId, userId]
    );
    
    if (result.affectedRows === 0) return res.status(403).json({ error: 'Admins cannot be removed.' });

    res.json({ success: true });
});

module.exports = router;