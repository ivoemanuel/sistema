// db/database.js
// Responsável por abrir a conexão com o SQLite, garantir que o schema exista
// e expor métodos utilitários baseados em Promise (run, get, all).

const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');

const DB_PATH = path.join(__dirname, 'dna_feed.sqlite');
const SCHEMA_PATH = path.join(__dirname, 'schema.sql');

const db = new sqlite3.Database(DB_PATH, (err) => {
    if (err) {
        console.error('[DB] Erro ao conectar no SQLite:', err.message);
        process.exit(1);
    }
    console.log('[DB] Conectado ao banco SQLite em', DB_PATH);
});

// Garante integridade referencial
db.run('PRAGMA foreign_keys = ON');

// Inicializa o schema (idempotente, usa CREATE TABLE IF NOT EXISTS)
function initSchema() {
    const schema = fs.readFileSync(SCHEMA_PATH, 'utf8');
    return new Promise((resolve, reject) => {
        db.exec(schema, (err) => {
            if (err) return reject(err);
            resolve();
        });
    });
}

// Wrappers em Promise para facilitar o uso com async/await nos controllers
function run(sql, params = []) {
    return new Promise((resolve, reject) => {
        db.run(sql, params, function (err) {
            if (err) return reject(err);
            resolve({ id: this.lastID, changes: this.changes });
        });
    });
}

function get(sql, params = []) {
    return new Promise((resolve, reject) => {
        db.get(sql, params, (err, row) => {
            if (err) return reject(err);
            resolve(row);
        });
    });
}

function all(sql, params = []) {
    return new Promise((resolve, reject) => {
        db.all(sql, params, (err, rows) => {
            if (err) return reject(err);
            resolve(rows);
        });
    });
}

module.exports = { db, initSchema, run, get, all };
