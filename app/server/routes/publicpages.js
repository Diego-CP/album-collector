const express = require('express');
const router = express.Router();

router.get('/signin', function(req, res){
    
    if (req.cookies?.access_token) {
        return res.redirect('/');
    }
    
    const state = require('crypto').randomUUID();
    res.cookie('oauth_state', state, { httpOnly: true, sameSite: 'lax' });
    res.render('signin', {
        cognitoDomain: process.env.COGNITO_DOMAIN,
        cognitoClientId: process.env.COGNITO_CLIENT_ID,
        cognitoRedirectUri: process.env.COGNITO_REDIRECT_URI,
        state
    }); 
});

module.exports = router;