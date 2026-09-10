# Changelog

Todas as mudanças notáveis deste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [1.1.0] - 2026-09-09

### Adicionado
- Nova pasta `scripts/` criada especificamente para isolar a inteligência de infraestrutura.
- `utils/shellRunner.js`: Módulo wrapper utilizando `child_process` para invocar os scripts em Shell de forma isolada.
- `routes/shellRoutes.js`: Endpoints do Express dedicados a receber os gatilhos para as automações.
- `controllers/shellController.js`: Lógica de negócio que valida requisições antes de acionar o terminal.

### Modificado
- `README.md`: Atualizado para refletir a nova arquitetura híbrida (Node.js + Shell) e documentar os scripts reais utilizados.
- Arquivos `sistema.sh`, `turnos.sh` e o backup `sistema.sh.bkp` foram movidos da raiz do projeto para dentro da nova pasta `scripts/`, organizando a estrutura.
- **Overhaul de UX/UI:** Refatoração do `style.css` e dos templates `.hbs` para um design system "Tech" (Ciano `#2596be` e fundos escuros `#1a1a1a` / `#2b2b2b`).
- Layout do Dashboard migrado para CSS Grid, distribuindo widgets na tela inicial.

---

## [1.0.0] - 2026-09-03

### Adicionado

#### Banco de dados
- Schema inicial do SQLite (`db/schema.sql`) com as tabelas `users`, `projects`, `feedbacks`, `feedback_notes` e `personal_notes`.
- Módulo de conexão (`db/database.js`) com wrapper em Promise (`run`, `get`, `all`) e inicialização automática do schema.
- Script de seed (`db/seed.js`) criando usuários iniciais (`admin`, `joao`, `maria`), projetos de exemplo e feedbacks de demonstração.
- Índices para otimizar consultas por usuário/data e por feedback.

#### Autenticação e segurança
- Motor de login baseado em sessão (`express-session` + `connect-sqlite3`), sem tela de cadastro público.
- Hash de senhas com `bcryptjs` (salt rounds = 10).
- Middleware de autorização (`requireAuth`, `requireAdmin`) protegendo todas as rotas privadas.
- Regeneração de sessão no login (mitigação de session fixation) e cookies `httpOnly`/`sameSite`.

#### Rotas e Controllers
- `authRoutes` / `authController`: login e logout.
- `dashboardRoutes` / `dashboardController`: tela inicial e criação de feedback diário.
- `historyRoutes` / `historyController`: histórico de feedbacks com filtros por data e projeto (e por usuário, para admins).
- `calendarRoutes` / `calendarController`: dados do calendário mensal com dias marcados.
- `feedbackRoutes` / `feedbackController`: detalhes de um feedback e adição de notas pela liderança (restrito a admins).
- `notesRoutes` / `notesController`: tela de notas pessoais e API JSON (`/api/notes`) para operações via `fetch`.

#### Views (Handlebars)
- Layout principal (`layouts/main.hbs`) e partial de navegação (`partials/navbar.hbs`).
- Tela de login (`login.hbs`).
- Dashboard com editor de texto rico e seletor de projeto (`dashboard.hbs`).
- Histórico com formulário de filtros (`history.hbs`).
- Calendário interativo (`calendar.hbs`).
- Detalhes do feedback com seção de notas da liderança (`feedback-details.hbs`).
- Notas pessoais / To-Do list (`personal-notes.hbs`).
- Tela de erro genérica (`error.hbs`).

#### Front-end (JS Vanilla + CSS puro)
- `public/js/dashboard.js`: barra de ferramentas do editor de texto rico (negrito, itálico, sublinhado, lista).
- `public/js/calendar.js`: renderização e navegação do calendário mensal, com destaque dos dias preenchidos.
- `public/js/notes.js`: CRUD de notas pessoais via `fetch`, sem recarregar a página.

#### Documentação
- `README.md` com arquitetura, modelo de dados, instruções de instalação e considerações de segurança.
- `CHANGELOG.md` (este arquivo).

### Segurança
- Todas as queries SQL parametrizadas para prevenir SQL Injection.
- Controle de acesso reforçado a nível de controller (usuário comum não acessa feedback de terceiros, mesmo manipulando a URL).

[1.1.0]: #
[1.0.0]: #