const path = require('path');
const http = require('http');
const express = require('express');

const socketio = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = socketio(server);
// Set static folder
// app.use(express.static(path.join(__dirname, 'public')));

// Run when a client connects
io.on('connection', socket => {
    socket.emit('message', 'Welcome To Transcribr');
    console.log('Welcome To Transcribr');
    // Broadcast when a user connects
    // socket.broadcast.emit('message', 'User has joined the chat');

    // Runs when a client disconnects

    // socket.on('disconnect', () => {
    //     io.emit('message', 'A user has left the chat');
    // });

    // Runs when a user sends a message
    socket.on('new message', (msg) => {
        io.emit('message', msg);
        console.log(msg);
    });
});

const PORT = 3000 || process.env.PORT;

server.listen(PORT, () => console.log(`Server running on port ${PORT}`));


// Setup
// var express = require('express')
// var app = express()
// var path = require('path');
// var server = require('http').createServer(app);
// var io = require('../..')(server);
// var port = process.env.PORT || 3000;

// server.listen(port, () => {
//     console.log('Server listening at port %d', port);
// });

// // Route

// app.use(express.static(path.join(__dirname, 'public')));

// // Chats

// var numUsers = 0;

// io.on('connection', (socket) => {
//     // var addedUser = false;

//     // new message handler
//     socket.on('new message', (data) => {
//         // execute
//         socket.broadcast.emit('new message', {
//             message: data
//         });
//     })

//     // disconnect from socket
//     // socket.on('disconnect', () => {
//     //     if
//     // })
// })