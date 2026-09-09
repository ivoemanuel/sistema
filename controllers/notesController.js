// controllers/notesController.js
const db = require('../db/database');

async function showPersonalNotes(req, res) {
    try {
        const notes = await db.all(
            'SELECT * FROM personal_notes WHERE user_id = ? ORDER BY status ASC, created_at DESC',
            [req.session.user.id]
        );
        res.render('personal-notes', {
            title: 'Notas Pessoais - DNA Feed',
            layout: 'main',
            active: 'notes',
            notes,
        });
    } catch (err) {
        console.error('[NOTES] Erro:', err);
        res.status(500).send('Erro ao carregar notas pessoais.');
    }
}

// --- Endpoints JSON usados pelo front-end (public/js/notes.js) ---

async function createNote(req, res) {
    try {
        const { content } = req.body;
        if (!content || !content.trim()) {
            return res.status(400).json({ error: 'Conteúdo obrigatório' });
        }
        const result = await db.run(
            'INSERT INTO personal_notes (user_id, content, status) VALUES (?, ?, ?)',
            [req.session.user.id, content.trim(), 'pendente']
        );
        const note = await db.get('SELECT * FROM personal_notes WHERE id = ?', [result.id]);
        res.status(201).json(note);
    } catch (err) {
        console.error('[NOTES] Erro ao criar:', err);
        res.status(500).json({ error: 'Erro interno' });
    }
}

async function toggleNote(req, res) {
    try {
        const { id } = req.params;
        const note = await db.get('SELECT * FROM personal_notes WHERE id = ? AND user_id = ?', [
            id,
            req.session.user.id,
        ]);
        if (!note) return res.status(404).json({ error: 'Nota não encontrada' });

        const newStatus = note.status === 'pendente' ? 'concluido' : 'pendente';
        await db.run('UPDATE personal_notes SET status = ? WHERE id = ?', [newStatus, id]);
        res.json({ id: Number(id), status: newStatus });
    } catch (err) {
        console.error('[NOTES] Erro ao atualizar:', err);
        res.status(500).json({ error: 'Erro interno' });
    }
}

async function deleteNote(req, res) {
    try {
        const { id } = req.params;
        await db.run('DELETE FROM personal_notes WHERE id = ? AND user_id = ?', [
            id,
            req.session.user.id,
        ]);
        res.json({ deleted: true });
    } catch (err) {
        console.error('[NOTES] Erro ao deletar:', err);
        res.status(500).json({ error: 'Erro interno' });
    }
}

module.exports = { showPersonalNotes, createNote, toggleNote, deleteNote };
