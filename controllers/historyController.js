// controllers/historyController.js
const db = require('../db/database');

async function showHistory(req, res) {
    try {
        const { project_id, start_date, end_date, user_id } = req.query;
        const isAdmin = req.session.user.role === 'admin';

        const projects = await db.all('SELECT * FROM projects ORDER BY name ASC');
        const users = isAdmin ? await db.all('SELECT id, username FROM users ORDER BY username ASC') : [];

        const conditions = [];
        const params = [];

        // Usuários comuns só enxergam os próprios feedbacks.
        // Admins podem, opcionalmente, filtrar por um usuário específico.
        if (!isAdmin) {
            conditions.push('f.user_id = ?');
            params.push(req.session.user.id);
        } else if (user_id) {
            conditions.push('f.user_id = ?');
            params.push(user_id);
        }

        if (project_id) {
            conditions.push('f.project_id = ?');
            params.push(project_id);
        }
        if (start_date) {
            conditions.push('f.date >= ?');
            params.push(start_date);
        }
        if (end_date) {
            conditions.push('f.date <= ?');
            params.push(end_date);
        }

        const whereClause = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

        const feedbacks = await db.all(
            `SELECT f.*, p.name AS project_name, u.username
             FROM feedbacks f
             LEFT JOIN projects p ON p.id = f.project_id
             LEFT JOIN users u ON u.id = f.user_id
             ${whereClause}
             ORDER BY f.date DESC, f.created_at DESC`,
            params
        );

        res.render('history', {
            title: 'Histórico - DNA Feed',
            layout: 'main',
            active: 'history',
            feedbacks,
            projects,
            users,
            isAdmin,
            filters: { project_id, start_date, end_date, user_id },
        });
    } catch (err) {
        console.error('[HISTORY] Erro:', err);
        res.status(500).send('Erro ao carregar o histórico.');
    }
}

module.exports = { showHistory };
