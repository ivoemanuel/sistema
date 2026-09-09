// public/js/notes.js
// Gerencia a lista de notas pessoais (To-Do) via chamadas fetch para a API JSON,
// sem recarregar a página.

document.addEventListener('DOMContentLoaded', () => {
    const list = document.getElementById('todo-list');
    const emptyState = document.getElementById('empty-state');
    const form = document.getElementById('new-note-form');
    const input = document.getElementById('new-note-input');

    let notes = [];
    try {
        notes = JSON.parse(list.dataset.notes || '[]');
    } catch (e) {
        notes = [];
    }

    function toggleEmptyState() {
        emptyState.style.display = notes.length === 0 ? 'block' : 'none';
    }

    function createItemElement(note) {
        const li = document.createElement('li');
        li.className = 'todo-item';
        li.dataset.id = note.id;

        const checkbox = document.createElement('button');
        checkbox.className = 'todo-item__checkbox' + (note.status === 'concluido' ? ' is-checked' : '');
        checkbox.type = 'button';
        checkbox.setAttribute('aria-label', 'Marcar como concluído');

        const text = document.createElement('span');
        text.className = 'todo-item__text' + (note.status === 'concluido' ? ' is-done' : '');
        text.textContent = note.content;

        const deleteBtn = document.createElement('button');
        deleteBtn.className = 'todo-item__delete';
        deleteBtn.type = 'button';
        deleteBtn.innerHTML = '&#10005;';
        deleteBtn.setAttribute('aria-label', 'Excluir nota');

        checkbox.addEventListener('click', () => toggleNote(note.id, checkbox, text));
        deleteBtn.addEventListener('click', () => deleteNote(note.id, li));

        li.appendChild(checkbox);
        li.appendChild(text);
        li.appendChild(deleteBtn);
        return li;
    }

    function renderAll() {
        list.innerHTML = '';
        notes.forEach((note) => list.appendChild(createItemElement(note)));
        toggleEmptyState();
    }

    async function toggleNote(id, checkboxEl, textEl) {
        try {
            const res = await fetch(`/api/notes/${id}/toggle`, { method: 'PATCH' });
            if (!res.ok) throw new Error('Falha ao atualizar');
            const data = await res.json();
            const note = notes.find((n) => n.id === id);
            if (note) note.status = data.status;
            checkboxEl.classList.toggle('is-checked', data.status === 'concluido');
            textEl.classList.toggle('is-done', data.status === 'concluido');
        } catch (err) {
            console.error(err);
            alert('Não foi possível atualizar a nota.');
        }
    }

    async function deleteNote(id, liEl) {
        if (!confirm('Excluir esta nota?')) return;
        try {
            const res = await fetch(`/api/notes/${id}`, { method: 'DELETE' });
            if (!res.ok) throw new Error('Falha ao excluir');
            notes = notes.filter((n) => n.id !== id);
            liEl.remove();
            toggleEmptyState();
        } catch (err) {
            console.error(err);
            alert('Não foi possível excluir a nota.');
        }
    }

    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        const content = input.value.trim();
        if (!content) return;

        try {
            const res = await fetch('/api/notes', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ content }),
            });
            if (!res.ok) throw new Error('Falha ao criar nota');
            const note = await res.json();
            notes.unshift(note);
            input.value = '';
            renderAll();
        } catch (err) {
            console.error(err);
            alert('Não foi possível adicionar a nota.');
        }
    });

    renderAll();
});
