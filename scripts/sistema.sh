#!/bin/bash
# ==========================================
# CONFIGURAÇÕES
# ==========================================

RAIZ="/opt/sistema"
LIB="$RAIZ/lib"

for arquivo in "$LIB"/*.sh; do
    source "$arquivo"
done

# ==========================================
# MENU PRINCIPAL
# ==========================================

verificar_estrutura
criar_registro

while true; do

    OPCOES=(
        "Turnos"
        "Registrar atividade"
        "Artigos"
        "Estudos"
        "Tarefas"
        "Diagnósticos"
        "Logs"
        "Feedback"
        "Sair"
    )

    selecionar_menu "${OPCOES[@]}"
    OPCAO=$?

    case $OPCAO in
        0) menu_turnos ;;
        1) registrar_atividade ;;
        2) menu_artigos ;;
        3) menu_estudos ;;
        4) menu_tarefas;;
        5) menu_diagnosticos ;;
        6) menu_logs ;;
        7) menu_feedback ;;
        8) clear ; exit 0 ;;
    esac

done
