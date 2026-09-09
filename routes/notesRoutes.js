// routes/notesRoutes.js
const express = require('express');
const router = express.Router();
const notesController = require('../controllers/notesController');
const { requireAuth } = require('../middlewares/authMiddleware');

router.get('/notes', requireAuth, notesController.showPersonalNotes);

// API JSON (usada via fetch no front-end)
router.post('/api/notes', requireAuth, notesController.createNote);
router.patch('/api/notes/:id/toggle', requireAuth, notesController.toggleNote);
router.delete('/api/notes/:id', requireAuth, notesController.deleteNote);

module.exports = router;
