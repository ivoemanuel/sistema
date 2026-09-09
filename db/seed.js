// db/seed.js
// Popula o banco com usuários (admin + membros da equipe) e projetos iniciais.
// Execução: npm run seed

const bcrypt = require('bcryptjs');
const { initSchema, run, get, all, db } = require('./database');

const SALT_ROUNDS = 10;

const USERS = [
    { username: 'admin', password: 'admin123', role: 'admin' },
    { username: 'laura', password: 'laura4747', role: 'admin' },
    { username: 'gabriel', password: 'gabriel4848', role: 'admin' },
    { username: 'vitor', password: 'vitor4949', role: 'user' },
    { username: 'rafael', password: 'rafal5050', role: 'user' },
    { username: 'leonardo', password: 'leonardo5151', role: 'user' },
    { username: 'lucas', password: 'lucas5252', role: 'user' },
    { username: 'daniele', password: 'daniele5353', role: 'user' },
    { username: 'rayssa', password: 'rayssa5454', role: 'user' },
    { username: 'emanuel', password: 'emanuel5555', role: 'user' },
    { username: 'jonh', password: 'jonh5656', role: 'user' },
    { username: 'bruno', password: 'bruno5757', role: 'user' },
];

const PROJECTS = ['Projeto DNA Mobile', 'Projeto DNA CERC'];

async function upsertUser(user) {
    const existing = await get('SELECT id FROM users WHERE username = ?', [user.username]);
    if (existing) {
        console.log(`[SEED] Usuário "${user.username}" já existe, pulando.`);
        return;
    }
    const hashed = await bcrypt.hash(user.password, SALT_ROUNDS);
    await run('INSERT INTO users (username, password, role) VALUES (?, ?, ?)', [
        user.username,
        hashed,
        user.role,
    ]);
    console.log(`[SEED] Usuário "${user.username}" (${user.role}) criado.`);
}

async function upsertProject(name) {
    const existing = await get('SELECT id FROM projects WHERE name = ?', [name]);
    if (existing) {
        console.log(`[SEED] Projeto "${name}" já existe, pulando.`);
        return;
    }
    await run('INSERT INTO projects (name) VALUES (?)', [name]);
    console.log(`[SEED] Projeto "${name}" criado.`);
}

async function seedSampleFeedbacks() {
    const vitor = await get('SELECT id FROM users WHERE username = ?', ['vitor']);
    const project = await get('SELECT id FROM projects WHERE name = ?', ['Projeto DNA Mobile']);
    if (!vitor || !project) return;

    const already = await get('SELECT id FROM feedbacks WHERE user_id = ?', [vitor.id]);
    if (already) {
        console.log('[SEED] Feedbacks de exemplo já existem, pulando.');
        return;
    }

    const today = new Date();
    for (let i = 0; i < 3; i++) {
        const d = new Date(today);
        d.setDate(d.getDate() - i);
        const dateStr = d.toISOString().slice(0, 10);
        await run(
            'INSERT INTO feedbacks (user_id, project_id, content, date) VALUES (?, ?, ?, ?)',
            [vitor.id, project.id, `<p>Feedback de exemplo do dia ${dateStr}.</p>`, dateStr]
        );
    }
    console.log('[SEED] Feedbacks de exemplo criados para o usuário "vitor".');
}

async function main() {
    console.log('[SEED] Inicializando schema...');
    await initSchema();

    console.log('[SEED] Criando usuários...');
    for (const u of USERS) {
        await upsertUser(u);
    }

    console.log('[SEED] Criando projetos...');
    for (const p of PROJECTS) {
        await upsertProject(p);
    }

    console.log('[SEED] Criando feedbacks de exemplo...');
    await seedSampleFeedbacks();

    console.log('\n[SEED] Concluído! Usuários disponíveis para login:');
    console.table(USERS.map((u) => ({ usuario: u.username, senha: u.password, role: u.role })));

    db.close();
}

main().catch((err) => {
    console.error('[SEED] Erro:', err);
    process.exit(1);
});
