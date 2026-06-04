const jwt = require('jsonwebtoken');
const jwksClient = require('jwks-rsa');

const client = jwksClient({
    jwksUri: `https://cognito-idp.${process.env.AWS_REGION}.amazonaws.com/${process.env.COGNITO_USER_POOL_ID}/.well-known/jwks.json`,
    cache: true,        // cache the public keys locally
    rateLimit: true
});

function getKey(header, callback) {
    client.getSigningKey(header.kid, (err, key) => {
        if (err) return callback(err);
        callback(null, key.getPublicKey());
    });
}

function authenticateToken(req, res, next) {
    const token = req.cookies?.access_token;

    if (!token) {
        if (req.path.startsWith('/api')) {
            return res.status(401).json({ error: 'No token provided.' });
        }
        return res.redirect('/public/signin');
    }

    jwt.verify(token, getKey, {
        issuer: `https://cognito-idp.${process.env.AWS_REGION}.amazonaws.com/${process.env.COGNITO_USER_POOL_ID}`,
        algorithms: ['RS256']
    }, (err, decoded) => {
        if (err) {
            if (req.path.startsWith('/api')) {
                return res.status(403).json({ error: 'Invalid or expired token.' });
            }
            return res.redirect('/public/signin');
        } 
        req.user = decoded;
        next();
    });
}

module.exports = authenticateToken;