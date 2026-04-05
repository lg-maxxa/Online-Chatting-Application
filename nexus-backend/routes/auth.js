const express = require('express');
const { body, validationResult } = require('express-validator');
const jwt = require('jsonwebtoken');
const rateLimit = require('express-rate-limit');
const User = require('../models/User');
const { protect } = require('../middleware/auth');

const router = express.Router();

const signToken = (id) =>
  jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || '7d' });

// Rate limiter for auth endpoints (10 requests per 15 minutes)
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: { message: 'Too many auth attempts. Please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
});

// ── POST /api/auth/register ─────────────────────────────────────────────────
router.post(
  '/register',
  authLimiter,
  [
    body('username')
      .trim()
      .isLength({ min: 3, max: 30 })
      .withMessage('Username must be 3–30 characters'),
    body('email').isEmail().withMessage('Invalid email address').normalizeEmail(),
    body('password')
      .isLength({ min: 8 })
      .withMessage('Password must be at least 8 characters'),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    try {
      const { username, email, password, phoneNumber } = req.body;

      const existingUser = await User.findOne({ $or: [{ email }, { username }] });
      if (existingUser) {
        return res.status(409).json({ message: 'Email or username already in use.' });
      }

      const user = await User.create({ username, email, password, phoneNumber });
      const token = signToken(user._id);

      return res.status(201).json({ token, user });
    } catch (err) {
      return res.status(500).json({ message: 'Server error during registration.' });
    }
  }
);

// ── POST /api/auth/login ────────────────────────────────────────────────────
router.post(
  '/login',
  authLimiter,
  [
    body('email').isEmail().withMessage('Invalid email address').normalizeEmail(),
    body('password').notEmpty().withMessage('Password is required'),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    try {
      const { email, password } = req.body;
      const user = await User.findOne({ email }).select('+password');

      if (!user || !(await user.comparePassword(password))) {
        return res.status(401).json({ message: 'Invalid email or password.' });
      }

      user.isOnline = true;
      user.lastSeen = new Date();
      await user.save({ validateBeforeSave: false });

      const token = signToken(user._id);
      return res.status(200).json({ token, user });
    } catch (err) {
      return res.status(500).json({ message: 'Server error during login.' });
    }
  }
);

// ── POST /api/auth/logout ───────────────────────────────────────────────────
router.post('/logout', protect, async (req, res) => {
  try {
    await User.findByIdAndUpdate(req.user._id, {
      isOnline: false,
      lastSeen: new Date(),
    });
    return res.status(200).json({ message: 'Logged out successfully.' });
  } catch (err) {
    return res.status(500).json({ message: 'Server error during logout.' });
  }
});

// ── GET /api/auth/me ────────────────────────────────────────────────────────
router.get('/me', protect, (req, res) => res.status(200).json({ user: req.user }));

module.exports = router;
