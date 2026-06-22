const express = require('express');
const router = express.Router();
const db = require('../db');

router.get('/', async function(req, res){
    const [[user]] = await db.execute(
        'SELECT display_name FROM users WHERE cognito_sub = ?', [req.user.sub]
    );

    res.render('homepage', { username: user.display_name });
});

router.get('/changeusername', function(req, res){
    res.render('changeusername');
});

router.get('/collection', function(req, res){
    res.render('collection'); 
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
    
    res.render('groupadmin', {
        groupId,
        inviteCode: results[0].invite_code,
        groupName: results[0].name,
        members: results.map(row => ({ user_id: row.user_id, username: row.display_name, role: row.role }))
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
        
    res.render('group', {
        groupId,
        inviteCode: results[0].invite_code,
        groupName: results[0].name,
        members: results.map(row => ({ user_id: row.user_id, username: row.display_name }))
    });
});

module.exports = router;