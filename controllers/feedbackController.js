// controllers/feedbackController.js
const db = require('../db/database');

async function showFeedbackDetails(req, res) {
    try {
        const { id } = req.params;
        const isAdmin = req.session.user.role === 'admin';

        const feedback = await db.get(
            `SELECT f.*, p.name AS project_name, u.username
             FROM feedbacks f
             LEFT JOIN projects p ON p.id = f.project_id
             LEFT JOIN users u ON u.id = f.user_id
             WHERE f.id = ?`,
            [id]
        );

        if (!feedback) {
            return res.status(404).render('error', {
                title: 'Não encontrado',
                message: 'Feedback não encontrado.',
                layout: 'main',
            });
        }

        // Usuário comum só pode ver os próprios feedbacks
        if (!isAdmin && feedback.user_id !== req.session.user.id) {
            return res.status(403).render('error', {
                title: 'Acesso negado',
                message: 'Você não tem permissão para visualizar este feedback.',
                layout: 'main',
            });
        }

        const notes = await db.all(
            `SELECT n.*, u.username AS admin_username
             FROM feedback_notes n
             LEFT JOIN users u ON u.id = n.admin_id
             WHERE n.feedback_id = ?
             ORDER BY n.created_at ASC`,
            [id]
        );

        res.render('feedback-details', {
            title: 'Detalhes do Feedback - DNA Feed',
            layout: 'main',
            feedback,
            notes,
            isAdmin,
            success: req.query.success,
        });
    } catch (err) {
        console.error('[FEEDBACK] Erro:', err);
        res.status(500).send('Erro ao carregar detalhes do feedback.');
    }
}

async function addNote(req, res) {
    try {
        const { id } = req.params;
        const { note_content } = req.body;

        if (!note_content || !note_content.trim()) {
            return res.redirect(`/feedback/${id}?error=Escreva uma nota antes de enviar`);
        }

        const feedback = await db.get('SELECT id FROM feedbacks WHERE id = ?', [id]);
        if (!feedback) {
            return res.status(404).send('Feedback não encontrado.');
        }

        await db.run(
            'INSERT INTO feedback_notes (feedback_id, admin_id, note_content) VALUES (?, ?, ?)',
            [id, req.session.user.id, note_content.trim()]
        );

        res.redirect(`/feedback/${id}?success=Nota adicionada com sucesso`);
    } catch (err) {
        console.error('[FEEDBACK] Erro ao adicionar nota:', err);
        res.status(500).send('Erro ao adicionar nota.');
    }
}

module.exports = { showFeedbackDetails, addNote };
