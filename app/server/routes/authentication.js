const axios = require('axios');
const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const db = require('../db');

router.get('/callback', async function(req, res) {
    const { code, state } = req.query;

    const storedState = req.cookies?.oauth_state;

    if (!code || !state || state !== storedState) {
        return res.redirect('/signin');
    }

    // Clear the state cookie immediately so it can't be reused
    res.clearCookie('oauth_state');

    // Exchange the code for tokens
    const params = new URLSearchParams({
        grant_type: 'authorization_code',
        client_id: process.env.COGNITO_CLIENT_ID,
        client_secret: process.env.COGNITO_CLIENT_SECRET,
        redirect_uri: process.env.COGNITO_REDIRECT_URI,
        code
    });

    try{
        const response = await axios.post(
            `${process.env.COGNITO_DOMAIN}/oauth2/token`,
            params,
            { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } }
        );

        const { access_token, id_token } = response.data;

        const { sub, email } = jwt.decode(id_token);

        const [[existing]] = await db.execute(
            'SELECT id FROM users WHERE cognito_sub = ?', [sub]
        );

        if (!existing) {
            const connection = await db.getConnection();

            try {
                await connection.beginTransaction();

                await connection.execute(
                    'INSERT INTO users (cognito_sub, email, display_name) VALUES (?, ?, "User")',
                    [sub, email]
                );

                await connection.execute(
                    `INSERT INTO collection (user_id, sticker_id)
                    SELECT u.id, s.id
                    FROM users u
                    CROSS JOIN stickers s
                    WHERE u.cognito_sub = ?`,
                    [sub]
                );

                await connection.commit();
            } catch(err) {
                await connection.rollback();
                throw err;
            } finally {
                connection.release();
            }
        }

        // Store the access token in an httpOnly cookie
        res.cookie('access_token', access_token, {
            httpOnly: true,   // JS can't read it, protects against XSS
            secure: process.env.NODE_ENV === 'production', // HTTPS only in prod
            sameSite: 'lax'
        });

        res.redirect(existing ? '/' : '/changeusername');
    } catch (err) {
        console.error('Cognito error:', {
            message: err.message,
            code: err.code,
            status: err.response?.status,
            data: err.response?.data,
        });
        
        // Instead of crashing, redirect back to signin
        res.redirect('/public/signin');
    }
});

router.get('/logout', function(req, res) {
    res.clearCookie('access_token');

    const logoutUrl = new URL(`${process.env.COGNITO_DOMAIN}/logout`);
    logoutUrl.searchParams.set('client_id', process.env.COGNITO_CLIENT_ID);
    logoutUrl.searchParams.set('logout_uri', process.env.COGNITO_LOGOUT_URI);

    res.redirect(logoutUrl.toString());
});

module.exports = router;