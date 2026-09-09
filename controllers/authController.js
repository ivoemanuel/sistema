// controllers/authController.js
const bcrypt = require('bcryptjs');
const db = require('../db/database');

function showLogin(req, res) {
    res.render('login', {
        title: 'Login - DNA Feed',
        layout: 'main',
        hideNav: true,
        error: req.query.error,
    });
}

async function login(req, res) {
    const { username, password } = req.body;

    try {
        if (!username || !password) {
            return res.redirect('/login?error=Preencha usuário e senha');
        }

        const user = await db.get('SELECT * FROM users WHERE username = ?', [username]);
        if (!user) {
            return res.redirect('/login?error=Usuário ou senha inválidos');
        }

        const match = await bcrypt.compare(password, user.password);
        if (!match) {
            return res.redirect('/login?error=Usuário ou senha inválidos');
        }

        // Regenera a sessão para evitar session fixation
        req.session.regenerate((err) => {
            if (err) {
                console.error(err);
                return res.redirect('/login?error=Erro interno, tente novamente');
            }
            req.session.user = { id: user.id, username: user.username, role: user.role };
            req.session.save(() => res.redirect('/dashboard'));
        });
    } catch (err) {
        console.error('[AUTH] Erro no login:', err);
        res.redirect('/login?error=Erro interno, tente novamente');
    }
}

function logout(req, res) {
    req.session.destroy(() => {
        res.clearCookie('connect.sid');
        res.redirect('/login');
    });
}

module.exports = { showLogin, login, logout };
