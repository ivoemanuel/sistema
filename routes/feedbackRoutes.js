// routes/feedbackRoutes.js
const express = require('express');
const router = express.Router();
const feedbackController = require('../controllers/feedbackController');
const { requireAuth, requireAdmin } = require('../middlewares/authMiddleware');

router.get('/feedback/:id', requireAuth, feedbackController.showFeedbackDetails);
router.post('/feedback/:id/notes', requireAuth, requireAdmin, feedbackController.addNote);

module.exports = router;
