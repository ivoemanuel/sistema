// server.js
// Ponto de entrada da aplicação DNA Feed.

const path = require('path');
const express = require('express');
const session = require('express-session');
const SQLiteStore = require('connect-sqlite3')(session);
const { engine } = require('express-handlebars');

const { initSchema } = require('./db/database');
const { injectUser } = require('./middlewares/authMiddleware');

const authRoutes = require('./routes/authRoutes');
const dashboardRoutes = require('./routes/dashboardRoutes');
const historyRoutes = require('./routes/historyRoutes');
const calendarRoutes = require('./routes/calendarRoutes');
const feedbackRoutes = require('./routes/feedbackRoutes');
const notesRoutes = require('./routes/notesRoutes');

const app = express();
const PORT = process.env.PORT || 3000;
const SESSION_SECRET = process.env.SESSION_SECRET || 'dna-feed-troque-este-segredo-em-producao';

// ----- Motor de Views (Handlebars) -----
app.engine(
    'hbs',
    engine({
        extname: '.hbs',
        defaultLayout: 'main',
        layoutsDir: path.join(__dirname, 'views/layouts'),
        partialsDir: path.join(__dirname, 'views/partials'),
        helpers: {
            eq: (a, b) => a === b,
            formatDate: (dateStr) => {
                if (!dateStr) return '';
                const [y, m, d] = dateStr.slice(0, 10).split('-');
                return `${d}/${m}/${y}`;
            },
            json: (context) => JSON.stringify(context),
            toString: (value) => String(value),
        },
    })
);
app.set('view engine', 'hbs');
app.set('views', path.join(__dirname, 'views'));

// ----- Middlewares globais -----
app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// ----- Sessão segura (persistida em SQLite) -----
app.use(
    session({
        store: new SQLiteStore({ db: 'sessions.sqlite', dir: path.join(__dirname, 'db') }),
        secret: SESSION_SECRET,
        resave: false,
        saveUninitialized: false,
        cookie: {
            httpOnly: true, // impede acesso via JS no browser (mitiga XSS)
            sameSite: 'lax', // mitiga CSRF básico
            maxAge: 1000 * 60 * 60 * 8, // 8 horas
            secure: false, // em localhost/HTTP; definir true atrás de HTTPS em produção
        },
    })
);

app.use(injectUser);

// ----- Rotas -----
app.get('/', (req, res) => res.redirect(req.session.user ? '/dashboard' : '/login'));

app.use(authRoutes);
app.use(dashboardRoutes);
app.use(historyRoutes);
app.use(calendarRoutes);
app.use(feedbackRoutes);
app.use(notesRoutes);

// ----- 404 -----
app.use((req, res) => {
    res.status(404).render('error', {
        title: 'Página não encontrada',
        message: 'A página que você procura não existe.',
        layout: 'main',
    });
});

// ----- Handler de erros -----
app.use((err, req, res, next) => {
    console.error('[SERVER] Erro não tratado:', err);
    res.status(500).render('error', {
        title: 'Erro interno',
        message: 'Algo deu errado no servidor.',
        layout: 'main',
    });
});

// ----- Inicialização -----
async function start() {
    try {
        await initSchema();
        app.listen(PORT, () => {
            console.log(`\n[DNA Feed] Servidor rodando em http://localhost:${PORT}`);
            console.log('[DNA Feed] Rode "npm run seed" antes do primeiro acesso, se ainda não o fez.\n');
        });
    } catch (err) {
        console.error('[SERVER] Falha ao iniciar:', err);
        process.exit(1);
    }
}

start();
