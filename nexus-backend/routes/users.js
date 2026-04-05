const express = require('express');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const { protect } = require('../middleware/auth');
const { upload } = require('../config/s3');

const router = express.Router();

// All routes require authentication
router.use(protect);

// ── GET /api/users/search?q=<query> ────────────────────────────────────────
router.get('/search', async (req, res) => {
  try {
    const { q } = req.query;
    if (!q || q.trim().length < 2) {
      return res.status(400).json({ message: 'Search query must be at least 2 characters.' });
    }

    const regex = new RegExp(q.trim(), 'i');
    const users = await User.find({
      _id: { $ne: req.user._id },
      $or: [{ username: regex }, { email: regex }],
    })
      .select('username email profilePicUrl status isOnline lastSeen')
      .limit(20);

    return res.status(200).json({ users });
  } catch (err) {
    return res.status(500).json({ message: 'Server error during user search.' });
  }
});

// ── GET /api/users/:id ──────────────────────────────────────────────────────
router.get('/:id', async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select(
      'username email profilePicUrl status isOnline lastSeen'
    );
    if (!user) return res.status(404).json({ message: 'User not found.' });
    return res.status(200).json({ user });
  } catch (err) {
    return res.status(500).json({ message: 'Server error.' });
  }
});

// ── PATCH /api/users/me/profile ─────────────────────────────────────────────
router.patch(
  '/me/profile',
  [
    body('status').optional().isLength({ max: 139 }).withMessage('Status max 139 chars'),
    body('phoneNumber').optional().isMobilePhone().withMessage('Invalid phone number'),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

    try {
      const allowed = ['username', 'status', 'phoneNumber', 'pushToken'];
      const updates = {};
      allowed.forEach((field) => {
        if (req.body[field] !== undefined) updates[field] = req.body[field];
      });

      const user = await User.findByIdAndUpdate(req.user._id, updates, {
        new: true,
        runValidators: true,
      });

      return res.status(200).json({ user });
    } catch (err) {
      return res.status(500).json({ message: 'Server error updating profile.' });
    }
  }
);

// ── POST /api/users/me/avatar ───────────────────────────────────────────────
router.post('/me/avatar', upload.single('avatar'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ message: 'No file uploaded.' });

    const profilePicUrl = req.file.location; // S3 URL
    const user = await User.findByIdAndUpdate(
      req.user._id,
      { profilePicUrl },
      { new: true }
    );

    return res.status(200).json({ profilePicUrl: user.profilePicUrl });
  } catch (err) {
    return res.status(500).json({ message: 'Error uploading avatar.' });
  }
});

// ── POST /api/users/me/contacts ─────────────────────────────────────────────
router.post('/me/contacts', async (req, res) => {
  try {
    const { contactId } = req.body;
    if (!contactId) return res.status(400).json({ message: 'contactId is required.' });

    const contact = await User.findById(contactId);
    if (!contact) return res.status(404).json({ message: 'User not found.' });

    await User.findByIdAndUpdate(req.user._id, {
      $addToSet: { contacts: contactId },
    });

    return res.status(200).json({ message: 'Contact added.' });
  } catch (err) {
    return res.status(500).json({ message: 'Server error adding contact.' });
  }
});

// ── GET /api/users/me/contacts ──────────────────────────────────────────────
router.get('/me/contacts', async (req, res) => {
  try {
    const user = await User.findById(req.user._id).populate(
      'contacts',
      'username email profilePicUrl status isOnline lastSeen'
    );
    return res.status(200).json({ contacts: user.contacts });
  } catch (err) {
    return res.status(500).json({ message: 'Server error fetching contacts.' });
  }
});

module.exports = router;
