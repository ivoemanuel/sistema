// middlewares/authMiddleware.js

/** Garante que o usuário esteja autenticado; caso contrário, redireciona para o login. */
function requireAuth(req, res, next) {
    if (req.session && req.session.user) {
        return next();
    }
    return res.redirect('/login');
}

/** Garante que o usuário autenticado tenha o papel de admin. */
function requireAdmin(req, res, next) {
    if (req.session && req.session.user && req.session.user.role === 'admin') {
        return next();
    }
    return res.status(403).render('error', {
        title: 'Acesso negado',
        message: 'Você não tem permissão para acessar este recurso.',
        layout: 'main',
        user: req.session.user,
    });
}

/** Redireciona usuários já logados para longe da tela de login. */
function redirectIfAuthenticated(req, res, next) {
    if (req.session && req.session.user) {
        return res.redirect('/dashboard');
    }
    return next();
}

/** Disponibiliza o usuário logado em todas as views (res.locals). */
function injectUser(req, res, next) {
    res.locals.currentUser = req.session ? req.session.user : null;
    next();
}

module.exports = { requireAuth, requireAdmin, redirectIfAuthenticated, injectUser };
