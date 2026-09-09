// public/js/dashboard.js
// Controla a barra de ferramentas do editor de texto rico (contenteditable)
// e prepara o conteúdo HTML para envio via formulário tradicional.

document.addEventListener('DOMContentLoaded', () => {
    const editor = document.getElementById('rich-editor');
    const hiddenInput = document.getElementById('content-input');
    const form = document.getElementById('feedback-form');
    const toolbarButtons = document.querySelectorAll('.rich-toolbar button');

    if (!editor) return;

    toolbarButtons.forEach((btn) => {
        btn.addEventListener('click', () => {
            const cmd = btn.dataset.cmd;
            editor.focus();
            document.execCommand(cmd, false, null);
        });
    });

    form.addEventListener('submit', (e) => {
        const html = editor.innerHTML.trim();
        if (!html || html === '<br>') {
            e.preventDefault();
            alert('Escreva algo no seu feedback antes de enviar.');
            editor.focus();
            return;
        }
        hiddenInput.value = html;
    });
});
