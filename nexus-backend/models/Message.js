const mongoose = require('mongoose');

const MESSAGE_TYPES = ['text', 'image', 'video', 'audio', 'file', 'location'];

const messageSchema = new mongoose.Schema(
  {
    chatId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Chat',
      required: true,
      index: true,
    },
    senderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    content: {
      type: String,
      default: '',
    },
    type: {
      type: String,
      enum: MESSAGE_TYPES,
      default: 'text',
    },
    mediaUrl: {
      type: String,
      default: '',
    },
    mediaKey: {
      type: String,
      default: '',
    },
    thumbnail: {
      type: String,
      default: '',
    },
    // For location messages
    location: {
      lat: { type: Number },
      lng: { type: Number },
    },
    readBy: [
      {
        userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        readAt: { type: Date, default: Date.now },
      },
    ],
    deliveredTo: [
      {
        userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        deliveredAt: { type: Date, default: Date.now },
      },
    ],
    isDeleted: {
      type: Boolean,
      default: false,
    },
    replyTo: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Message',
      default: null,
    },
  },
  { timestamps: true }
);

// Compound index for paginated message fetching
messageSchema.index({ chatId: 1, createdAt: -1 });

module.exports = mongoose.model('Message', messageSchema);
