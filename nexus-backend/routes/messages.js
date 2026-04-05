const express = require('express');
const Message = require('../models/Message');
const Chat = require('../models/Chat');
const { protect } = require('../middleware/auth');
const { upload } = require('../config/s3');

const router = express.Router();

router.use(protect);

// Helper: verify user is participant of a chat
const verifyParticipant = async (chatId, userId) => {
  const chat = await Chat.findOne({ _id: chatId, participants: userId });
  return chat;
};

// ── GET /api/messages/:chatId ───────────────────────────────────────────────
// Paginated messages for a chat (cursor-based pagination)
router.get('/:chatId', async (req, res) => {
  try {
    const chat = await verifyParticipant(req.params.chatId, req.user._id);
    if (!chat) return res.status(403).json({ message: 'Access denied.' });

    const limit = Math.min(parseInt(req.query.limit, 10) || 30, 100);
    const before = req.query.before; // ISO date string for cursor-based pagination

    const query = { chatId: req.params.chatId, isDeleted: false };
    if (before) query.createdAt = { $lt: new Date(before) };

    const messages = await Message.find(query)
      .populate('senderId', 'username profilePicUrl')
      .populate('replyTo')
      .sort({ createdAt: -1 })
      .limit(limit);

    return res.status(200).json({ messages: messages.reverse() });
  } catch (err) {
    return res.status(500).json({ message: 'Error fetching messages.' });
  }
});

// ── POST /api/messages/:chatId ──────────────────────────────────────────────
// Send a text message
router.post('/:chatId', async (req, res) => {
  try {
    const chat = await verifyParticipant(req.params.chatId, req.user._id);
    if (!chat) return res.status(403).json({ message: 'Access denied.' });

    const { content, type = 'text', replyTo } = req.body;
    if (!content && type === 'text') {
      return res.status(400).json({ message: 'Message content is required.' });
    }

    const message = await Message.create({
      chatId: req.params.chatId,
      senderId: req.user._id,
      content,
      type,
      replyTo: replyTo || null,
    });

    // Update chat's last message
    await Chat.findByIdAndUpdate(req.params.chatId, {
      lastMessage: message._id,
      lastMessageAt: message.createdAt,
    });

    const populated = await message.populate('senderId', 'username profilePicUrl');
    return res.status(201).json({ message: populated });
  } catch (err) {
    return res.status(500).json({ message: 'Error sending message.' });
  }
});

// ── POST /api/messages/:chatId/media ────────────────────────────────────────
// Upload media file and create message
router.post('/:chatId/media', upload.single('media'), async (req, res) => {
  try {
    const chat = await verifyParticipant(req.params.chatId, req.user._id);
    if (!chat) return res.status(403).json({ message: 'Access denied.' });
    if (!req.file) return res.status(400).json({ message: 'No file uploaded.' });

    const mimeToType = {
      image: 'image',
      video: 'video',
      audio: 'audio',
    };
    const mimeCategory = req.file.mimetype.split('/')[0];
    const messageType = mimeToType[mimeCategory] || 'file';

    const message = await Message.create({
      chatId: req.params.chatId,
      senderId: req.user._id,
      content: req.body.caption || '',
      type: messageType,
      mediaUrl: req.file.location,
      mediaKey: req.file.key,
    });

    await Chat.findByIdAndUpdate(req.params.chatId, {
      lastMessage: message._id,
      lastMessageAt: message.createdAt,
    });

    const populated = await message.populate('senderId', 'username profilePicUrl');
    return res.status(201).json({ message: populated });
  } catch (err) {
    return res.status(500).json({ message: 'Error uploading media.' });
  }
});

// ── PATCH /api/messages/:messageId/read ─────────────────────────────────────
// Mark a message as read by the current user
router.patch('/:messageId/read', async (req, res) => {
  try {
    const message = await Message.findById(req.params.messageId);
    if (!message) return res.status(404).json({ message: 'Message not found.' });

    const alreadyRead = message.readBy.some(
      (r) => r.userId.toString() === req.user._id.toString()
    );

    if (!alreadyRead) {
      message.readBy.push({ userId: req.user._id });
      await message.save();
    }

    return res.status(200).json({ message });
  } catch (err) {
    return res.status(500).json({ message: 'Error marking message as read.' });
  }
});

// ── DELETE /api/messages/:messageId ─────────────────────────────────────────
// Soft-delete a message (sender only)
router.delete('/:messageId', async (req, res) => {
  try {
    const message = await Message.findById(req.params.messageId);
    if (!message) return res.status(404).json({ message: 'Message not found.' });
    if (message.senderId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'You can only delete your own messages.' });
    }

    message.isDeleted = true;
    message.content = '';
    await message.save();

    return res.status(200).json({ message: 'Message deleted.' });
  } catch (err) {
    return res.status(500).json({ message: 'Error deleting message.' });
  }
});

module.exports = router;
