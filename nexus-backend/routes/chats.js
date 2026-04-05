const express = require('express');
const mongoose = require('mongoose');
const Chat = require('../models/Chat');
const Message = require('../models/Message');
const User = require('../models/User');
const { protect } = require('../middleware/auth');

const router = express.Router();

router.use(protect);

const isValidObjectId = (id) => mongoose.Types.ObjectId.isValid(id);

// ── GET /api/chats ──────────────────────────────────────────────────────────
// List all chats for the authenticated user
router.get('/', async (req, res) => {
  try {
    const chats = await Chat.find({ participants: req.user._id })
      .populate('participants', 'username profilePicUrl isOnline lastSeen')
      .populate('lastMessage')
      .sort({ lastMessageAt: -1 });

    return res.status(200).json({ chats });
  } catch (err) {
    return res.status(500).json({ message: 'Error fetching chats.' });
  }
});

// ── POST /api/chats ─────────────────────────────────────────────────────────
// Create or retrieve a direct (1-on-1) chat
router.post('/', async (req, res) => {
  try {
    const { participantId } = req.body;
    if (!participantId) return res.status(400).json({ message: 'participantId is required.' });
    if (!isValidObjectId(participantId)) {
      return res.status(400).json({ message: 'Invalid participantId.' });
    }

    const otherUser = await User.findById(participantId);
    if (!otherUser) return res.status(404).json({ message: 'User not found.' });

    // Return existing direct chat if one already exists
    let chat = await Chat.findOne({
      isGroup: false,
      participants: { $all: [req.user._id, participantId], $size: 2 },
    })
      .populate('participants', 'username profilePicUrl isOnline lastSeen')
      .populate('lastMessage');

    if (!chat) {
      chat = await Chat.create({
        participants: [req.user._id, participantId],
        isGroup: false,
      });
      chat = await chat.populate('participants', 'username profilePicUrl isOnline lastSeen');
    }

    return res.status(200).json({ chat });
  } catch (err) {
    return res.status(500).json({ message: 'Error creating chat.' });
  }
});

// ── POST /api/chats/group ───────────────────────────────────────────────────
// Create a group chat
router.post('/group', async (req, res) => {
  try {
    const { participantIds, groupName } = req.body;
    if (!participantIds || !Array.isArray(participantIds) || participantIds.length < 2) {
      return res.status(400).json({ message: 'At least 2 participants required for a group.' });
    }
    if (!groupName || groupName.trim().length < 1) {
      return res.status(400).json({ message: 'Group name is required.' });
    }

    const allParticipants = [...new Set([req.user._id.toString(), ...participantIds])];

    const chat = await Chat.create({
      isGroup: true,
      groupName: groupName.trim(),
      participants: allParticipants,
      admins: [req.user._id],
    });

    const populated = await chat.populate(
      'participants',
      'username profilePicUrl isOnline lastSeen'
    );

    return res.status(201).json({ chat: populated });
  } catch (err) {
    return res.status(500).json({ message: 'Error creating group chat.' });
  }
});

// ── GET /api/chats/:chatId ──────────────────────────────────────────────────
router.get('/:chatId', async (req, res) => {
  try {
    const chat = await Chat.findOne({
      _id: req.params.chatId,
      participants: req.user._id,
    })
      .populate('participants', 'username profilePicUrl isOnline lastSeen status')
      .populate('lastMessage');

    if (!chat) return res.status(404).json({ message: 'Chat not found.' });
    return res.status(200).json({ chat });
  } catch (err) {
    return res.status(500).json({ message: 'Error fetching chat.' });
  }
});

module.exports = router;
