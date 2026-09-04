#!/bin/bash

OPCOES=(
    "Ver último turno"
    "Registrar atividade"
    "Ver registro de hoje"
    "Ver histórico"
    "Artigos"
    "Estudos"
    "Logs"
    "Gerar feedback"
    "Editar feedback"
    "Sair"
)

SELECIONADO=0

while true; do
    clear

    echo "========== REGISTRO DE TURNOS =========="
    echo

    for i in "${!OPCOES[@]}"; do
        if [[ $i -eq $SELECIONADO ]]; then
            echo "❯ ${OPCOES[$i]}"
        else
            echo "  ${OPCOES[$i]}"
        fi
    done

    echo
    echo "↑ ↓ navegar | ENTER selecionar"

    IFS= read -rsn1 TECLA

    if [[ "$TECLA" == $'\x1b' ]]; then

        read -rsn2 TECLA

        case "$TECLA" in
            "[A")
                ((SELECIONADO--))
                ;;
            "[B")
                ((SELECIONADO++))
                ;;
        esac

    elif [[ "$TECLA" == "" ]]; then
        break
    fi

    if (( SELECIONADO < 0 )); then
        SELECIONADO=$((${#OPCOES[@]} - 1))
    fi

    if (( SELECIONADO >= ${#OPCOES[@]} )); then
        SELECIONADO=0
    fi

done

echo
echo "Você selecionou: ${OPCOES[$SELECIONADO]}"