require('dotenv').config({ path: './app/.env' })

// Importing required packages
const http = require('http');
const express = require('express');
const cookieParser = require('cookie-parser');
const authenticateToken = require('./app/middleware/auth');

const app = express();

app.set('port', process.env.PORT || 3000); // Application port is set
app.set('views', __dirname + '/app/server/views'); // Views folder is set
app.set('view engine', 'ejs'); // View engine is set
app.use(express.static(__dirname + '/app/public')); // Public folder containing static files is set
app.use(express.json()); // For parsing JSON request bodies
app.use(cookieParser());

// Public routes: 
// Authentication routes
app.use('/auth', require('./app/server/routes/authentication'));

// Public pages
app.use('/public', require('./app/server/routes/publicpages'));

app.use(authenticateToken);

// Protected routes:
// Page routes
app.use('/', require('./app/server/routes/pages'));

// Group API routes
app.use('/api/groups', require('./app/server/routes/groups'));

// User API routes
app.use('/api/users', require('./app/server/routes/users'));

// Collection API routes
app.use('/api/collections', require('./app/server/routes/collections'));

const server = http.createServer(app).listen(app.get('port'), function(){
	console.log('The application is running on port ' + app.get('port'));
}); // Http server is created

module.exports = server;