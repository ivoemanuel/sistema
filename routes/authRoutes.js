// routes/authRoutes.js
const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { redirectIfAuthenticated } = require('../middlewares/authMiddleware');

router.get('/login', redirectIfAuthenticated, authController.showLogin);
router.post('/login', redirectIfAuthenticated, authController.login);
router.post('/logout', authController.logout);
router.get('/logout', authController.logout); // conveniência para link simples

module.exports = router;
