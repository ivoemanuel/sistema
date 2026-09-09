# DNA Feed

**DNA Feed** é uma aplicação web para que membros de equipe registrem e acompanhem seus relatórios de atividades diárias (feedbacks), com um espaço para que a liderança adicione notas de acompanhamento a cada registro.

Construída para rodar em **localhost**, com foco em simplicidade, modularização (padrão MVC) e boas práticas básicas de segurança.

---

## Sumário

- [Stack Tecnológica](#stack-tecnológica)
- [Arquitetura e Estrutura de Pastas](#arquitetura-e-estrutura-de-pastas)
- [Modelo de Dados](#modelo-de-dados)
- [Pré-requisitos](#pré-requisitos)
- [Instalação e Primeira Execução](#instalação-e-primeira-execução)
- [Usuários de Teste](#usuários-de-teste)
- [Funcionalidades](#funcionalidades)
- [Segurança](#segurança)
- [Scripts Disponíveis](#scripts-disponíveis)
- [Possíveis Evoluções](#possíveis-evoluções)

---

## Stack Tecnológica

| Camada          | Tecnologia                                   |
|-----------------|-----------------------------------------------|
| Back-end        | Node.js + Express                             |
| Views           | Handlebars (`express-handlebars`)             |
| Front-end       | CSS puro + JavaScript Vanilla (sem frameworks)|
| Banco de dados  | SQLite (via `sqlite3`)                        |
| Sessão          | `express-session` + `connect-sqlite3`         |
| Senhas          | `bcryptjs` (hash + salt)                      |

Nenhum framework de front-end (React/Vue/etc.) é utilizado — todas as interações dinâmicas (editor de texto rico, calendário, lista de notas) são implementadas em JavaScript Vanilla puro, consumindo endpoints Express.

---

## Arquitetura e Estrutura de Pastas

O projeto segue o padrão **MVC** (Model-View-Controller), com uma separação estrita de responsabilidades:

```
dna-feed/
├── server.js                  # Ponto de entrada da aplicação
├── package.json
├── .gitignore
├── README.md
├── CHANGELOG.md
│
├── db/                         # Camada de dados (Model)
│   ├── database.js             # Conexão + wrapper Promise (run/get/all)
│   ├── schema.sql               # Definição das tabelas
│   ├── seed.js                  # Script de carga inicial (usuários/projetos)
│   └── dna_feed.sqlite          # Arquivo do banco (gerado em runtime)
│
├── routes/                     # Definição das rotas Express (uma por domínio)
│   ├── authRoutes.js
│   ├── dashboardRoutes.js
│   ├── historyRoutes.js
│   ├── calendarRoutes.js
│   ├── feedbackRoutes.js
│   └── notesRoutes.js
│
├── controllers/                # Lógica de negócio (Controller)
│   ├── authController.js
│   ├── dashboardController.js
│   ├── historyController.js
│   ├── calendarController.js
│   ├── feedbackController.js
│   └── notesController.js
│
├── middlewares/
│   └── authMiddleware.js       # requireAuth, requireAdmin, injectUser...
│
├── views/                       # Templates Handlebars (View)
│   ├── layouts/main.hbs
│   ├── partials/navbar.hbs
│   ├── login.hbs
│   ├── dashboard.hbs
│   ├── history.hbs
│   ├── calendar.hbs
│   ├── feedback-details.hbs
│   ├── personal-notes.hbs
│   └── error.hbs
│
└── public/                      # Assets estáticos
    ├── css/style.css
    └── js/
        ├── dashboard.js         # Editor de texto rico (toolbar)
        ├── calendar.js          # Renderização do calendário
        └── notes.js             # CRUD de notas pessoais via fetch/API
```

**Fluxo de uma requisição:** `routes/*` recebe a requisição → aplica `middlewares` (autenticação/autorização) → delega para `controllers/*` → controller consulta `db/database.js` → resultado é passado para uma `view/*.hbs`, renderizada dentro do `layouts/main.hbs`.

---

## Modelo de Dados

```
users
 ├── id            INTEGER PK
 ├── username       TEXT UNIQUE
 ├── password       TEXT (hash bcrypt)
 ├── role           TEXT ('admin' | 'user')
 └── created_at     DATETIME

projects
 ├── id            INTEGER PK
 └── name          TEXT UNIQUE

feedbacks
 ├── id            INTEGER PK
 ├── user_id       INTEGER FK -> users.id
 ├── project_id    INTEGER FK -> projects.id (nullable)
 ├── content       TEXT (HTML do editor rico)
 ├── date          TEXT (YYYY-MM-DD)
 └── created_at    DATETIME

feedback_notes
 ├── id            INTEGER PK
 ├── feedback_id   INTEGER FK -> feedbacks.id
 ├── admin_id      INTEGER FK -> users.id
 ├── note_content  TEXT
 └── created_at    DATETIME

personal_notes
 ├── id            INTEGER PK
 ├── user_id       INTEGER FK -> users.id
 ├── content       TEXT
 ├── status        TEXT ('pendente' | 'concluido')
 └── created_at    DATETIME
```

O schema completo está em [`db/schema.sql`](./db/schema.sql) e é aplicado automaticamente (via `CREATE TABLE IF NOT EXISTS`) toda vez que o servidor sobe.

---

## Pré-requisitos

- **Node.js** 18 ou superior (recomendado LTS)
- **npm** 9 ou superior (instalado junto com o Node.js)
- Nenhum banco de dados externo é necessário — o SQLite roda em arquivo local.

---

## Instalação e Primeira Execução

```bash
# 1. Entre na pasta do projeto
cd dna-feed

# 2. Instale as dependências
npm install

# 3. Popule o banco com usuários e projetos iniciais
npm run seed

# 4. Inicie o servidor
npm start
```

Acesse **http://localhost:3000** no navegador. Você será redirecionado para a tela de login.

> Para alterar a porta, defina a variável de ambiente `PORT` (ex.: `PORT=4000 npm start`).
> Para trocar o segredo de sessão (recomendado antes de qualquer uso além de testes locais), defina `SESSION_SECRET`.

---

## Funcionalidades

### Login
Autenticação simples baseada em sessão. Não há tela de cadastro público — todos os usuários são provisionados via `db/seed.js` (ou diretamente no banco).

### Dashboard / Início (`/dashboard`)
Campo de "feedback diário" com editor de texto rico (negrito, itálico, sublinhado, listas) implementado em JavaScript Vanilla via `contenteditable` + `document.execCommand`, e um seletor de projeto vinculado.

### Histórico (`/history`)
Lista os feedbacks já registrados, com filtros por **data (de/até)** e por **projeto**. Usuários comuns veem apenas os próprios registros; administradores podem filtrar também por membro da equipe.

### Calendário (`/calendar`)
Calendário mensal navegável (mês anterior/próximo) construído em JS puro, com os dias em que o usuário registrou feedback visualmente destacados na cor de destaque (ciano).

### Detalhes e Notas da Liderança (`/feedback/:id`)
Tela de detalhe de um feedback específico. Usuários com `role = admin` podem adicionar **notas** àquele feedback; usuários comuns podem visualizar as notas recebidas, mas não editá-las.

### Notas Pessoais (`/notes`)
Lista de afazeres/rascunhos privada do usuário logado (não visível a outros usuários, nem à liderança). CRUD completo (criar, marcar como concluído, excluir) feito via `fetch` para uma pequena API JSON (`/api/notes/*`), sem recarregar a página.

---

## Segurança

Mesmo sendo uma aplicação de uso local, o projeto segue práticas recomendadas:

- **Senhas com hash**: nunca armazenadas em texto puro — `bcryptjs` com salt (`SALT_ROUNDS = 10`).
- **Sessões seguras**: cookies `httpOnly` (inacessíveis via JavaScript no navegador, mitigando XSS) e `sameSite: 'lax'` (mitigação básica de CSRF); sessão persistida em SQLite (`connect-sqlite3`) em vez de memória.
- **Regeneração de sessão no login**: evita ataques de *session fixation*.
- **Autorização em duas camadas**: `requireAuth` (usuário logado) e `requireAdmin` (apenas liderança) aplicados por rota, e reforçados também na camada de controller (ex.: um usuário comum não consegue abrir `/feedback/:id` de outro usuário, mesmo manipulando a URL).
- **Parametrização de queries**: todas as consultas SQL usam parâmetros (`?`) — nunca concatenação de strings —, prevenindo SQL Injection.
- **Segredo de sessão configurável**: via variável de ambiente `SESSION_SECRET` (um valor padrão é usado apenas como fallback para desenvolvimento).

> Para uso além de localhost/rede interna, recomenda-se: servir via HTTPS e ativar `cookie.secure = true`, adicionar um middleware de CSRF token dedicado (ex.: `csurf`), e mover segredos para um arquivo `.env` fora do controle de versão.

---

## Scripts Disponíveis

| Comando          | Descrição                                             |
|-------------------|--------------------------------------------------------|
| `npm install`     | Instala as dependências do projeto                     |
| `npm run seed`    | Cria/atualiza usuários, projetos e dados de exemplo     |
| `npm start`       | Inicia o servidor em `http://localhost:3000`            |
| `npm run dev`     | Alias de `npm start` (mesmo comportamento)              |

---