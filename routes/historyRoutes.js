// routes/historyRoutes.js
const express = require('express');
const router = express.Router();
const historyController = require('../controllers/historyController');
const { requireAuth } = require('../middlewares/authMiddleware');

router.get('/history', requireAuth, historyController.showHistory);

module.exports = router;
