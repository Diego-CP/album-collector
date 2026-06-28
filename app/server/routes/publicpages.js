const express = require('express');
const router = express.Router();

router.get('/signin', function(req, res){
    
    if (req.cookies?.access_token) {
        return res.redirect('/');
    }
    
    const state = req.cookies?.oauth_state || require('crypto').randomUUID();
    res.cookie('oauth_state', state, { 
        httpOnly: true, 
        sameSite: 'lax',
        maxAge: 10 * 60 * 1000 // 10 minutes
    });

    res.render('signin', {
        cognitoDomain: process.env.COGNITO_DOMAIN,
        cognitoClientId: process.env.COGNITO_CLIENT_ID,
        cognitoRedirectUri: process.env.COGNITO_REDIRECT_URI,
        state
    }); 
});

module.exports = router;