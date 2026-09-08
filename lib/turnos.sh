#!/bin/bash
# ==========================================
# CRIAR ARQUIVO DO DIA
# ==========================================

criar_registro() {

    DATA=$(date '+%d-%m-%Y')
    HORA=$(date '+%H:%M')

    if [ ! -f "$ARQUIVO" ]; then

        cat > "$ARQUIVO" << EOF
========================================
           REGISTRO DE TURNOS
========================================

DATA: $DATA
USUARIO: $USUARIO
INICIO: $HORA

========================================

EOF

    fi

}

# ==========================================
# MOSTRAR REGISTRO DE HOJE
# ==========================================

mostrar_hoje() {
    local OPCOES LINHAS_ARQUIVO ESCOLHA LINHA_SELECIONADA
    local HORA_L CATEGORIA_L MARCADOR_L USUARIO_L ATIVIDADE_L
    local NOVA_ATIVIDADE TEMP_HOJE CONFIRMACAO

    while true; do
        clear
        echo "========================================"
        echo "            REGISTRO DE HOJE"
        echo "========================================"
        echo

        OPCOES=()
        LINHAS_ARQUIVO=()
        while IFS= read -r LINHA; do
            if [[ "$LINHA" != *"|"* ]]; then continue; fi
            OPCOES+=("$LINHA")
            LINHAS_ARQUIVO+=("$LINHA")
        done < "$ARQUIVO"
    
        if [[ ${#OPCOES[@]} -eq 0 ]]; then
            echo "Nenhuma atividade registrada ainda hoje"
            echo
            read -rp "Pressione ENTER para voltar..."
        fi

        OPCOES+=("Voltar")
        HABILITAR_DEL=1
        selecionar_menu "${OPCOES[@]}"
        ESCOLHA=$?

        if [[ $ESCOLHA -eq $(( ${#OPCOES[@]} - 1)) ]]; then
            break
        fi

        LINHA_SELECIONADA="${LINHAS_ARQUIVO[$ESCOLHA]}"
        IFS='|' read -r HORA_L CATEGORIA_L MARCADOR_L USUARIO_L ATIVIDADE_L <<< "$LINHA_SELECIONADA"
        HORA_L=$(echo "$HORA_L" | sed 's/^ *//;s/ *$//')
        CATEGORIA_L=$(echo "$CATEGORIA_L" | sed 's/^ *//;s/ *$//')
        MARCADOR_L=$(echo "$MARCADOR_L" | sed 's/^ *//;s/ *$//')
        USUARIO_L=$(echo "$USUARIO_L" | sed 's/^ *//;s/ *$//')
        ATIVIDADE_L=$(echo "$ATIVIDADE_L" | sed 's/^ *//;s/ *$//')
    
        if [[ "$USUARIO_L" != "$USUARIO" ]]; then
            echo
            echo "[ ERRO ]: Você só pode editar ou remover atividades registradas por você" 
            read -rp "Pressione ENTER para voltar..."
            continue
        fi

        if [[ "$ACAO_MENU" == "DEL" ]]; then
            echo
            read -rp "Tem certeza que deseja EXCLUIR essa atividade? [s/N]: " CONFIRMACAO
            if [[ "$CONFIRMACAO" =~ ^[sS]$ ]]; then
                TEMP_HOJE=$(mktemp)
                grep -vF "$LINHA_SELECIONADA" "$ARQUIVO" > "$TEMP_HOJE"
                mv "$TEMP_HOJE" "$ARQUIVO"
            fi
            continue
        fi

        echo
        read -e -i "$ATIVIDADE_L" -rp "Editar atividade: " NOVA_ATIVIDADE

        if [[ -z "$NOVA_ATIVIDADE" ]]; then
            echo
            echo "A atividade não pode ficar vazia"
            read -rp "Pressione ENTER para voltar..."
            continue
        fi

        echo
        read -rp "Confirma salvar essa alteração? [s/N]: " CONFIRMACAO
        if [[ ! "$CONFIRMACAO" =~ ^[sS]$ ]]; then
            echo
            echo "Alteração cancelada"
            read -rp "Pressione ENTER para voltar..."
            continue
        fi

        TEMP_HOJE=$(mktemp)
        while IFS= read -r LINHA; do
            if [[ "$LINHA" == "$LINHA_SELECIONADA" ]]; then
                echo "${HORA_L} | ${CATEGORIA_L} | ${MARCADOR_L} | ${USUARIO_L} | $NOVA_ATIVIDADE" >> "$TEMP_HOJE"
            else
                echo "$LINHA" >> "$TEMP_HOJE"
            fi
        done < "$ARQUIVO"
        mv "$TEMP_HOJE" "$ARQUIVO"

        echo
        echo "Atividade atualizada com sucesso!"
        read -rp "Pressione ENTER para voltar..."
    done
}

# ==========================================
# REGISTRAR ATIVIDADE
# ==========================================

registrar_atividade() {
    clear
    local OPCOES=(
        "Rotina"
        "Alteração crítica"
        "Artigo"
        "Explicação"
        "Problema"
        "Observação"
        "Voltar"
    )

    local TIPO CATEGORIA ATIVIDADE MARCADOR FEEDBACK

    selecionar_menu "${OPCOES[@]}"
    TIPO=$?

    case $TIPO in
        0) CATEGORIA="ROTINA" ;;
        1) CATEGORIA="ALTERACOES" ;;
        2) CATEGORIA="ARTIGOS" ;;
        3) CATEGORIA="EXPLICACOES" ;;
        4) CATEGORIA="PROBLEMAS" ;;
        5) CATEGORIA="OBSERVACOES" ;;
        6) clear ; return ;;
    esac
    echo
    read -rp "Descreva o que foi feito: " ATIVIDADE

    if [ -z "$ATIVIDADE" ]; then

        echo
        echo "A atividade não pode estar vazia."
        sleep 2
        return

    fi

    HORA=$(date '+%H:%M')

    read -p "Deseja incluir no feedback? [s/N]:" FEEDBACK

    if [[ "$FEEDBACK" =~ ^[sS]$ ]]; then
        MARCADOR="S"
    else
        MARCADOR="N"
    fi

    echo "[$HORA] | $CATEGORIA | $MARCADOR | $USUARIO | $ATIVIDADE" >> "$ARQUIVO"

    echo
    echo "Atividade registrada com sucesso!"
    echo
    read -rp "Pressione ENTER para voltar..."

}

# ==========================================
# DESCOBRIR ÚLTIMO TURNO
# ==========================================

obter_ultimo_turno() {

    ls -1 "$DIR_REGISTROS"/*.txt 2>/dev/null \
        | sort \
        | grep -v "$ARQUIVO" \
        | tail -n 1

}

# ==========================================
# MOSTRAR ÚLTIMO TURNO
# ==========================================

mostrar_ultimo_turno() {
    clear
    echo "========================================"
    echo "          ÚLTIMO TURNO"
    echo "========================================"
    echo

    local ULTIMO_ARQUIVO
    ULTIMO_ARQUIVO=$(obter_ultimo_turno)

    if [ -z "$ULTIMO_ARQUIVO" ]; then
        echo "Nenhum turno anterior encontrado."
    else
        cat "$ULTIMO_ARQUIVO"
    fi

    echo
    echo "========================================"
    read -rp "Pressione ENTER para voltar..."
}

# ==========================================
# HISTÓRICO
# ==========================================

mostrar_historico() {
    local OPCOES ARQUIVOS_ENCONTRADOS NOME_ARQUIVO ESCOLHA 

    while true; do 
        clear
        echo "========================================"
        echo "             HISTÓRICO"
        echo "========================================"
        echo

        if ! ls "$DIR_REGISTROS"/*.txt >/dev/null 2>&1; then

            echo "Nenhum registro encontrado."
            echo
            read -rp "Pressione ENTER para voltar..."
            return
        fi

        OPCOES=() # zera a cada volta
        ARQUIVOS_ENCONTRADOS=()

        while IFS= read -r NOME_ARQUIVO; do
            if [[ -z "$NOME_ARQUIVO" ]]; then continue; fi
            OPCOES+=("$(basename "$NOME_ARQUIVO" .txt)")
            ARQUIVOS_ENCONTRADOS+=("$NOME_ARQUIVO")
        done < <(ls -1 "$DIR_REGISTROS"/*.txt | sort -r)

        OPCOES+=("Voltar")

        selecionar_menu "${OPCOES[@]}"
        ESCOLHA=$?

        if [[ $ESCOLHA -eq $(( ${#OPCOES[@]} - 1 )) ]]; then
           break 
        fi

        clear
        echo "========================================"
        echo "  REGISTRO: ${OPCOES[$ESCOLHA]}"
        echo "========================================"
        echo
        cat "${ARQUIVOS_ENCONTRADOS[$ESCOLHA]}"
        echo
        echo "========================================"
        read -rp "Pressione ENTER para voltar ao histórico..."
    done
}

resumo_turno() {
    clear
    echo "========== RESUMO DO TURNO =========="
    echo

    if [[ ! -f "$ARQUIVO" ]] || ! grep -q "|" "$ARQUIVO"; then
        echo "Nenhuma atividade registrada ainda hoje"
        echo
        read -rp "Pressione ENTER para voltar..."
        return
    fi

    local CATEGORIA_R CONTAGEM TOTAL_FEEDBACK

    echo "--- Por categoria ---"
    for CATEGORIA_R in ROTINA ALTERACOES ARTIGOS EXPLICACOES PROBLEMAS OBSERVACOES; do
        CONTAGEM=$(grep -c "| $CATEGORIA_R |" "$ARQUIVO" )
        if [[ "$CONTAGEM" -gt 0 ]]; then
            echo "$CATEGORIA_R: $CONTAGEM"
        fi
    done

    echo
    TOTAL_FEEDBACK=$(grep -c "| S |" "$ARQUIVO" )
    echo "--- Marcada(s) para feedback ---"
    echo "$TOTAL_FEEDBACK"

    echo
    read -rp "Pressione ENTER para voltar..."
}


menu_turnos() {
    local OPCOES
    while true; do
        clear
        echo "========== TURNOS =========="
        echo

        OPCOES=(
            "Ver último turno"
            "Ver registro de hoje"
            "Ver histórico"
            "Resumo do turno"
            "Voltar"
        )

        selecionar_menu "${OPCOES[@]}"
        local ESCOLHA="$?"

        case "$ESCOLHA" in
            0) mostrar_ultimo_turno ;;
            1) mostrar_hoje ;;
            2) mostrar_historico ;;
            3) resumo_turno ;;
            4) break ;;
        esac
    done
}