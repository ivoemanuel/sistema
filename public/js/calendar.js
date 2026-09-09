// public/js/calendar.js
// Renderiza um calendário mensal em JS puro, destacando os dias em que
// o usuário registrou feedback (dados injetados via data-attributes pelo servidor).

document.addEventListener('DOMContentLoaded', () => {
    const app = document.getElementById('calendar-app');
    if (!app) return;

    let year = parseInt(app.dataset.year, 10);
    let month = parseInt(app.dataset.month, 10); // 1-12
    let markedDays = [];
    try {
        markedDays = JSON.parse(app.dataset.marked || '[]');
    } catch (e) {
        markedDays = [];
    }

    const WEEKDAYS = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    const MONTH_NAMES = [
        'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
        'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
    ];

    const titleEl = document.getElementById('calendar-title');
    const weekdaysEl = document.getElementById('calendar-weekdays');
    const daysEl = document.getElementById('calendar-days');

    function pad(n) {
        return String(n).padStart(2, '0');
    }

    async function fetchMarkedDays(y, m) {
        try {
            const res = await fetch(`/calendar?year=${y}&month=${m}`, {
                headers: { 'X-Requested-With': 'fetch' },
            });
            const text = await res.text();
            const parser = new DOMParser();
            const doc = parser.parseFromString(text, 'text/html');
            const newApp = doc.getElementById('calendar-app');
            if (newApp) {
                return JSON.parse(newApp.dataset.marked || '[]');
            }
        } catch (e) {
            console.error('Erro ao buscar dias marcados:', e);
        }
        return [];
    }

    function render() {
        titleEl.textContent = `${MONTH_NAMES[month - 1]} de ${year}`;

        weekdaysEl.innerHTML = WEEKDAYS.map((w) => `<div class="calendar__weekday">${w}</div>`).join('');

        const firstDay = new Date(year, month - 1, 1);
        const startWeekday = firstDay.getDay(); // 0 = domingo
        const daysInMonth = new Date(year, month, 0).getDate();

        const todayStr = new Date().toISOString().slice(0, 10);

        let html = '';
        for (let i = 0; i < startWeekday; i++) {
            html += '<div class="calendar__day calendar__day--empty"></div>';
        }

        for (let day = 1; day <= daysInMonth; day++) {
            const dateStr = `${year}-${pad(month)}-${pad(day)}`;
            const isFilled = markedDays.includes(dateStr);
            const isToday = dateStr === todayStr;
            const classes = [
                'calendar__day',
                isFilled ? 'calendar__day--filled' : '',
                isToday ? 'calendar__day--today' : '',
            ].filter(Boolean).join(' ');
            html += `<div class="${classes}" title="${dateStr}">${day}</div>`;
        }

        daysEl.innerHTML = html;

        // Atualiza a URL sem recarregar a página
        const url = new URL(window.location);
        url.searchParams.set('year', year);
        url.searchParams.set('month', month);
        window.history.replaceState({}, '', url);
    }

    async function goToMonth(newYear, newMonth) {
        year = newYear;
        month = newMonth;
        markedDays = await fetchMarkedDays(year, month);
        render();
    }

    document.getElementById('prev-month').addEventListener('click', () => {
        let newMonth = month - 1;
        let newYear = year;
        if (newMonth < 1) {
            newMonth = 12;
            newYear -= 1;
        }
        goToMonth(newYear, newMonth);
    });

    document.getElementById('next-month').addEventListener('click', () => {
        let newMonth = month + 1;
        let newYear = year;
        if (newMonth > 12) {
            newMonth = 1;
            newYear += 1;
        }
        goToMonth(newYear, newMonth);
    });

    render();
});
