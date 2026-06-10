const express = require('express');
const router = express.Router();

router.get('/', function(req, res){
    res.render('homepage');
});

router.get('/createaccount', function(req, res){
    res.render('createaccount');
});

router.get('/collection', function(req, res){
    res.render('collection'); 
});

router.get('/collection/edit', function(req, res){
    res.render('editcollection'); 
});

router.get('/join', function(req, res){
    res.render('joingroup'); 
});

router.get('/creategroup', function(req, res){
    res.render('creategroup'); 
});

router.get('/group/:groupId', function(req, res){
    const { groupId } = req.params;

    db.query(`SELECT g.invite_code, gm.user_id, u.username
        FROM user_groups g
        LEFT JOIN group_members gm ON g.id = gm.group_id
        LEFT JOIN users u ON gm.user_id = u.id
        WHERE g.id = ?`, 
        [groupId], (err, results) => {
        if (err || results.length === 0) return res.status(404).send('Group not found');
        
        res.render('group', {
            inviteCode: results[0].invite_code,
            members: results.map(row => ({ user_id: row.user_id, username: row.username }))
        });    
    });
});

router.get('/group/admin/:groupId', function(req, res){
    const { groupId } = req.params;

    db.query(`SELECT g.invite_code, gm.user_id, u.username
        FROM user_groups g
        LEFT JOIN group_members gm ON g.id = gm.group_id
        LEFT JOIN users u ON gm.user_id = u.id
        WHERE g.id = ?`, 
        [groupId], (err, results) => {
        if (err || results.length === 0) return res.status(404).send('Group not found');
        
        res.render('groupadmin', {
            inviteCode: results[0].invite_code,
            members: results.map(row => ({ user_id: row.user_id, username: row.username }))
        });    
    });
});

module.exports = router;