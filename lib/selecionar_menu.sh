#!/bin/bash
# =============================================================================
#                               MENU DE NAVEGAÇÂO
# =============================================================================
# TABELA DE REFERÊNCIA DE CORES ANSI PARA TERMINAL LINUX
# Uso: \e[ESTILO;TEXTO;FUNDOm  (Terminar sempre com \e[0m)
# Exemplo: echo -e "\e[1;32;44m Texto \e[0m" (Negrito, Texto Verde, Fundo Azul)
# =============================================================================
# ESTILOS:
# 0 = Reset/Normal  |  1 = Negrito (Bold)  |  4 = Sublinhado  |  7 = Invertido
# -----------------------------------------------------------------------------
# CORES DE TEXTO (Foreground)         | CORES DE FUNDO (Background)
# 30 / 90 = Preto (Normal / Brilhante)| 40 / 100 = Preto
# 31 / 91 = Vermelho                  | 41 / 101 = Vermelho
# 32 / 92 = Verde                     | 42 / 102 = Verde
# 33 / 93 = Amarelo                   | 43 / 103 = Amarelo
# 34 / 94 = Azul                      | 44 / 104 = Azul
# 35 / 95 = Magenta / Roxo            | 45 / 105 = Magenta / Roxo
# 36 / 96 = Ciano / Azul Claro        | 46 / 106 = Ciano / Azul Claro
# 37 / 97 = Branco / Cinza            | 47 / 107 = Branco / Cinza
# =============================================================================

selecionar_menu() {
    local COR_DESTAQUE="\e[48;2;138;43;226m" 
    local RESET="\e[0m"
    local OPCOES=("$@")
    local SELECIONADO=0
    local TECLA

    ACAO_MENU="ENTER"

    while true; do
        clear

        # Imprime o cabeçalho/contexto antes do menu, caso a variável tenha sido setada
        if [[ -n "$MENSAGEM_MENU" ]]; then
            echo -e "$MENSAGEM_MENU"
        fi

        for i in "${!OPCOES[@]}"; do
            if [[ $i -eq $SELECIONADO ]]; then
                echo -e "${COR_DESTAQUE} 🐧 ${OPCOES[$i]} ${RESET}"
            else
                echo "  ${OPCOES[$i]}"
            fi
        done

        if [[ "$HABILITAR_DEL" == "1" ]]; then
            echo
            echo "↑ ↓ navegar | ENTER selecionar | DEL remover"
        else
            echo
            echo "↑ ↓ navegar | ENTER selecionar"
        fi

        IFS= read -rsn1 TECLA

        # BACKSPACE
        if [[ "$TECLA" == $'\x7f' || "$TECLA" == $'\x08' ]]; then
            ACAO_MENU="BACK"
            return 255
        fi

        # ENTER
        if [[ "$TECLA" == "" ]]; then
            return "$SELECIONADO"
        fi

        # SETAS
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
        fi

        # Volta para o último item
        if (( SELECIONADO < 0 )); then
            SELECIONADO=$((${#OPCOES[@]} - 1))
        fi

        # Volta para o primeiro item
        if (( SELECIONADO >= ${#OPCOES[@]} )); then
            SELECIONADO=0
        fi

        if [[ "$TECLA" == $'\x1b' ]]; then
            read -rsn2 TECLA
            case "$TECLA" in
                "[A") ((SELECIONADO--)) ;;
                "[B") ((SELECIONADO++)) ;;
                "[3")
                    if [[ "$HABILITAR_DEL" == "1" ]]; then
                        # Pega o "~" final do código da tecla Delete (\e[3~)
                        read -rsn1 TECLA_TIL
                        if [[ "$TECLA_TIL" == "~" ]]; then
                            ACAO_MENU="DEL"
                            break
                        fi
                    fi
                    ;;
            esac
        elif [[ -z "$TECLA" ]]; then
            ACAO_MENU="ENTER"
            break
        fi

        if (( SELECIONADO < 0 )); then
            SELECIONADO=$((${#OPCOES[@]} - 1))
        fi

        if (( SELECIONADO >= ${#OPCOES[@]} )); then
            SELECIONADO=0
        fi
    done

    # Destrói os gatilhos globais antes de sair para não afetar menus subsequentes
    HABILITAR_DEL=0
    MENSAGEM_MENU=""

    return "$SELECIONADO"
}