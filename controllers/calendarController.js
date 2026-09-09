// controllers/calendarController.js
const db = require('../db/database');

async function showCalendar(req, res) {
    try {
        const year = parseInt(req.query.year, 10) || new Date().getFullYear();
        const month = parseInt(req.query.month, 10) || new Date().getMonth() + 1; // 1-12

        const monthStr = String(month).padStart(2, '0');
        const prefix = `${year}-${monthStr}`;

        const rows = await db.all(
            `SELECT DISTINCT date FROM feedbacks WHERE user_id = ? AND date LIKE ?`,
            [req.session.user.id, `${prefix}%`]
        );
        const markedDays = rows.map((r) => r.date);

        res.render('calendar', {
            title: 'Calendário - DNA Feed',
            layout: 'main',
            active: 'calendar',
            year,
            month,
            markedDaysJSON: JSON.stringify(markedDays),
        });
    } catch (err) {
        console.error('[CALENDAR] Erro:', err);
        res.status(500).send('Erro ao carregar o calendário.');
    }
}

module.exports = { showCalendar };
