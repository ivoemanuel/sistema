// routes/calendarRoutes.js
const express = require('express');
const router = express.Router();
const calendarController = require('../controllers/calendarController');
const { requireAuth } = require('../middlewares/authMiddleware');

router.get('/calendar', requireAuth, calendarController.showCalendar);

module.exports = router;
