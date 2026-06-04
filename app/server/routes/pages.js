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

router.get('/group/:groupCode', function(req, res){
    res.render('group'); 
});

module.exports = router;

// TODO: Make Group Owner page and redirect based on user role in the group
