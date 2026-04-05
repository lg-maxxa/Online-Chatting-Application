/**
 * NexusChat – Professional Social Media Platform
 * Main Server Entry Point
 *
 * Stack: Node.js + Express + Socket.io + MongoDB Atlas + AWS S3
 * Deployment: Azure App Service
 */

require('dotenv').config();

const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

const connectDB = require('./config/db');
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const chatRoutes = require('./routes/chats');
const messageRoutes = require('./routes/messages');

// ── Database Connection ────────────────────────────────────────────────────
connectDB();

// ── Express App ────────────────────────────────────────────────────────────
const app = express();
const server = http.createServer(app);

// ── CORS Configuration ─────────────────────────────────────────────────────
// In production, set CLIENT_ORIGIN to your Flutter app's domain or use '*' only for dev.
const allowedOrigins = process.env.CLIENT_ORIGIN
  ? process.env.CLIENT_ORIGIN.split(',').map((o) => o.trim())
  : null;

const originValidator = (origin, callback) => {
  // Allow requests with no origin (mobile apps, server-to-server)
  if (!origin) return callback(null, true);
  if (!allowedOrigins || allowedOrigins.includes(origin)) {
    return callback(null, true);
  }
  return callback(new Error('Not allowed by CORS'));
};

const corsOptions = {
  origin: originValidator,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
};

// ── Socket.io Setup ────────────────────────────────────────────────────────
const io = new Server(server, {
  cors: {
    origin: originValidator,
    methods: ['GET', 'POST'],
  },
});

// ── Global Middleware ──────────────────────────────────────────────────────
app.use(helmet());
app.use(cors(corsOptions));
app.use(express.json({ limit: '1mb' }));
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

// Global rate limiter (100 requests per 15 minutes per IP)
app.use(
  rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100,
    standardHeaders: true,
    legacyHeaders: false,
    message: { message: 'Too many requests. Please slow down.' },
  })
);

// ── Routes ─────────────────────────────────────────────────────────────────
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/chats', chatRoutes);
app.use('/api/messages', messageRoutes);

// Health check endpoint (used by Azure App Service)
app.get('/health', (_req, res) => res.status(200).json({ status: 'ok' }));

// 404 handler
app.use((_req, res) => res.status(404).json({ message: 'Route not found.' }));

// Global error handler
// eslint-disable-next-line no-unused-vars
app.use((err, _req, res, _next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({ message: err.message || 'Internal server error.' });
});

// ── Socket.io Real-time Logic ──────────────────────────────────────────────
// Map of userId -> Set of socketIds (supports multiple devices)
const onlineUsers = new Map();

io.on('connection', (socket) => {
  console.log(`🔌 Socket connected: ${socket.id}`);

  // ── Authentication via handshake query ──────────────────────────────────
  const { userId } = socket.handshake.auth;

  if (userId) {
    if (!onlineUsers.has(userId)) onlineUsers.set(userId, new Set());
    onlineUsers.get(userId).add(socket.id);
    socket.join(`user_${userId}`); // personal room for targeted events
    io.emit('user_online', { userId });
  }

  // ── Join a chat room ─────────────────────────────────────────────────────
  socket.on('join_chat', (chatId) => {
    socket.join(chatId);
  });

  // ── Leave a chat room ────────────────────────────────────────────────────
  socket.on('leave_chat', (chatId) => {
    socket.leave(chatId);
  });

  // ── Send a message (real-time relay) ────────────────────────────────────
  socket.on('send_message', (data) => {
    // data = { chatId, message }  (message already saved via REST API)
    socket.to(data.chatId).emit('receive_message', data.message);
  });

  // ── Typing indicators ────────────────────────────────────────────────────
  socket.on('typing_start', ({ chatId, userId: typingUserId }) => {
    socket.to(chatId).emit('typing_start', { userId: typingUserId });
  });

  socket.on('typing_stop', ({ chatId, userId: typingUserId }) => {
    socket.to(chatId).emit('typing_stop', { userId: typingUserId });
  });

  // ── Message read receipts ────────────────────────────────────────────────
  socket.on('message_read', ({ chatId, messageId, readerId }) => {
    socket.to(chatId).emit('message_read', { messageId, readerId });
  });

  // ── Disconnect ───────────────────────────────────────────────────────────
  socket.on('disconnect', () => {
    if (userId) {
      const sockets = onlineUsers.get(userId);
      if (sockets) {
        sockets.delete(socket.id);
        if (sockets.size === 0) {
          onlineUsers.delete(userId);
          io.emit('user_offline', { userId });
        }
      }
    }
    console.log(`🔌 Socket disconnected: ${socket.id}`);
  });
});

// ── Start Server ───────────────────────────────────────────────────────────
// Only bind the port when this file is the entry point (not required by tests)
if (require.main === module) {
  const PORT = process.env.PORT || 5000;
  server.listen(PORT, () => {
    console.log(`🚀 NexusChat server running on port ${PORT} [${process.env.NODE_ENV || 'development'}]`);
  });
}

module.exports = { app, server, io }; // exported for testing
