// controllers/dashboardController.js
const db = require('../db/database');

async function showDashboard(req, res) {
    try {
        const projects = await db.all('SELECT * FROM projects ORDER BY name ASC');
        const todayStr = new Date().toISOString().slice(0, 10);

        const todaysFeedbacks = await db.all(
            `SELECT f.*, p.name AS project_name
             FROM feedbacks f
             LEFT JOIN projects p ON p.id = f.project_id
             WHERE f.user_id = ? AND f.date = ?
             ORDER BY f.created_at DESC`,
            [req.session.user.id, todayStr]
        );

        res.render('dashboard', {
            title: 'Início - DNA Feed',
            layout: 'main',
            active: 'dashboard',
            projects,
            todaysFeedbacks,
            todayStr,
            success: req.query.success,
        });
    } catch (err) {
        console.error('[DASHBOARD] Erro:', err);
        res.status(500).send('Erro ao carregar o dashboard.');
    }
}

async function createFeedback(req, res) {
    try {
        const { content, project_id, date } = req.body;
        const cleanContent = (content || '').trim();

        if (!cleanContent || cleanContent === '<br>') {
            return res.redirect('/dashboard?error=Escreva um feedback antes de enviar');
        }

        const feedbackDate = date || new Date().toISOString().slice(0, 10);

        await db.run(
            'INSERT INTO feedbacks (user_id, project_id, content, date) VALUES (?, ?, ?, ?)',
            [req.session.user.id, project_id || null, cleanContent, feedbackDate]
        );

        res.redirect('/dashboard?success=Feedback registrado com sucesso!');
    } catch (err) {
        console.error('[DASHBOARD] Erro ao criar feedback:', err);
        res.status(500).send('Erro ao registrar feedback.');
    }
}

module.exports = { showDashboard, createFeedback };
