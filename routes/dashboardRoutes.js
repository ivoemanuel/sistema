// routes/dashboardRoutes.js
const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/dashboardController');
const { requireAuth } = require('../middlewares/authMiddleware');

router.get('/dashboard', requireAuth, dashboardController.showDashboard);
router.post('/dashboard/feedback', requireAuth, dashboardController.createFeedback);

module.exports = router;
