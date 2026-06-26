const express = require('express');
const router = express.Router();
const db = require('../db');

function groupTradeRows(tradeRows) {
    const tradesMap = new Map();

    for (const row of tradeRows) {
        if (!tradesMap.has(row.trade_id)) {
            tradesMap.set(row.trade_id, { id: row.trade_id, steps: [] });
        }
        tradesMap.get(row.trade_id).steps.push({
            step_order: row.step_order,
            from_user: row.from_user,
            to_user: row.to_user,
            sticker_name: row.sticker_name,
            sticker_code: row.sticker_code,
            quantity: row.quantity,
        });
    }

    return Array.from(tradesMap.values());
}

router.get('/', async function(req, res){
    const [[user]] = await db.execute(
        'SELECT id, display_name FROM users WHERE cognito_sub = ?', [req.user.sub]
    );

    const [groups] = await db.execute(
        `SELECT ug.id, ug.name, gm.role
         FROM group_members gm
         JOIN user_groups ug ON gm.group_id = ug.id
         WHERE gm.user_id = ?`,
        [user.id]
    );

    res.render('homepage', { username: user.display_name, groups });
});

router.get('/changeusername', function(req, res){
    res.render('changeusername');
});

router.get('/collection', async function(req, res) {
    const [stickers] = await db.query(
        `SELECT s.id, s.sticker_code, s.name, s.section, s.sticker_type,
                COALESCE(c.needs, 1) AS needs,
                COALESCE(c.duplicates_amount, 0) AS duplicates_amount
         FROM stickers s
         LEFT JOIN collection c ON c.sticker_id = s.id AND c.user_id = (SELECT id FROM users WHERE cognito_sub = ?)
         ORDER BY s.section, s.id`,
        [req.user.sub]
    );

    const stickersJson = JSON.stringify(
        Object.fromEntries(
            stickers.map(s => [s.id, { needs: s.needs === 1, duplicates_amount: s.duplicates_amount }])
        )
    );

    res.render('collection', { stickers, stickersJson });
});

router.get('/join', function(req, res){
    res.render('joingroup'); 
});

router.get('/creategroup', function(req, res){
    res.render('creategroup'); 
});

router.get('/group/admin/:groupId', async function(req, res){
    const { groupId } = req.params;

    const [results] = await db.query(`SELECT g.invite_code, g.name, gm.user_id, gm.role, u.display_name, u.cognito_sub
        FROM user_groups g
        LEFT JOIN group_members gm ON g.id = gm.group_id
        LEFT JOIN users u ON gm.user_id = u.id
        WHERE g.id = ?`, 
        [groupId]);
    
    if (!results.length) return res.status(404).send('Group not found');

    const currentUser = results.find(row => row.cognito_sub === req.user.sub);
    if (!currentUser || currentUser.role !== 'admin') return res.status(403).send('Forbidden');

    const [tradeRows] = await db.query(`
        SELECT t.id AS trade_id,
               ts.step_order,
               ts.quantity,
               fu.display_name AS from_user,
               tu.display_name AS to_user,
               s.name AS sticker_name,
               s.sticker_code
        FROM trades t
        JOIN trade_steps ts ON ts.trade_id = t.id
        JOIN users fu ON fu.id = ts.from_user_id
        JOIN users tu ON tu.id = ts.to_user_id
        JOIN stickers s ON s.id = ts.sticker_id
        WHERE t.group_id = ? AND t.status = 'available'
        ORDER BY t.id, ts.step_order`,
        [groupId]);

    const trades = groupTradeRows(tradeRows);

    res.render('groupadmin', {
        groupId,
        inviteCode: results[0].invite_code,
        groupName: results[0].name,
        members: results.map(row => ({ user_id: row.user_id, username: row.display_name, role: row.role })),
        trades,
    });
});

router.get('/group/:groupId', async function(req, res){
    const { groupId } = req.params;

    const [results] = await db.query(`SELECT g.invite_code, g.name, gm.user_id, u.display_name, u.cognito_sub
        FROM user_groups g
        LEFT JOIN group_members gm ON g.id = gm.group_id
        LEFT JOIN users u ON gm.user_id = u.id
        WHERE g.id = ?`, 
        [groupId]);
    
    if (!results.length) return res.status(404).send('Group not found');

    const isMember = results.some(row => row.cognito_sub === req.user.sub);
    if (!isMember) return res.status(403).send('Forbidden');

    const [tradeRows] = await db.query(`
        SELECT t.id AS trade_id,
               ts.step_order,
               ts.quantity,
               fu.display_name AS from_user,
               tu.display_name AS to_user,
               s.name AS sticker_name,
               s.sticker_code
        FROM trades t
        JOIN trade_steps ts ON ts.trade_id = t.id
        JOIN users fu ON fu.id = ts.from_user_id
        JOIN users tu ON tu.id = ts.to_user_id
        JOIN stickers s ON s.id = ts.sticker_id
        WHERE t.group_id = ? AND t.status = 'available'
        ORDER BY t.id, ts.step_order`,
        [groupId]);

    const trades = groupTradeRows(tradeRows);
        
    res.render('group', {
        groupId,
        inviteCode: results[0].invite_code,
        groupName: results[0].name,
        members: results.map(row => ({ user_id: row.user_id, username: row.display_name })),
        trades,
    });
});

module.exports = router;