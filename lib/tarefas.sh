#!/bin/bash
# ==========================================
# TAREFAS
# ==========================================

add_tarefa() {
    clear
    echo "========================================"
    echo "            ADICIONAR TAREFA"
    echo "========================================"
    echo

    local DESCRICAO ID OPCOES_PRIORIDADE PRIORIDADE

    read -e -rp "Breve descrição da tarefa: " DESCRICAO

    if [[ -z "$DESCRICAO" ]]; then
        echo
        echo "A descrição não pode estar vazia"
        read -rp "Pressione ENTER para voltar..."
        return
    fi

    OPCOES_PRIORIDADE=("Alta" "Média" "Baixa")
    selecionar_menu "${OPCOES_PRIORIDADE[@]}"


    case $? in
        0) PRIORIDADE="ALTA" ;;
        1) PRIORIDADE="MEDIA" ;;
        2) PRIORIDADE="BAIXA" ;;
    esac

    echo
    echo "Defina o nível de prioridade para esta tarefa"
    echo


    if [[ ! -s "$ARQ_AFAZERES" ]]; then
        ID=1
    else
        ID=$(awk -F'|' 'NF >= 1 {print $1}' "$ARQ_AFAZERES" | sort -n | tail -n 1)
        ID=$((ID + 1))
    fi

    echo "$ID|ABERTA|$PRIORIDADE|$DESCRICAO" >> "$ARQ_AFAZERES"

    echo
    echo "Tarefa adicionada com sucesso!"
    read -rp "Pressione ENTER para voltar... "
}

ls_tarefas() {
    # declaração segura fora do loop
    local OPCOES IDS STATUS_LIST PRIORIDADE_LIST DESCRICOES ID STATUS PRIORIDADES DESC
    local COR_VERDE="\e[38;5;46m" COR_AMARELO="\e[38;2;255;255;0m" COR_VERMELHO="\e[38;2;255;0;0m" RESET="\e[0m" COR_AZUL="\e[38;2;0;191;255m"

    while true; do
        clear
        echo "========================================"
        echo "            LISTA DE TAREFAS"
        echo "========================================"
        echo

        if [[ ! -s "$ARQ_AFAZERES" ]]; then
            echo
            echo "Nenhuma tarefa cadastrada"
            echo
            read -rp "Pressione ENTER para voltar..."
            return
        fi

        # zera os arrays a cada volta para evitar itens "fantasmas"
        OPCOES=()
        IDS=()
        STATUS_LIST=()
        PRIORIDADE_LIST=()
        DESCRICOES=()

        # monta a visualização limpando qualquer caractere de controle do sistema
        while IFS="|" read -r ID STATUS PRIORIDADE DESC || [[ -n "$ID" ]]; do
            # remove espaços vazios acidentais e quebras de linha invisíveis
            ID=$(echo "$ID" | tr -d '\r')
            STATUS=$(echo "$STATUS" | tr -d '\r')
            PRIORIDADE=$(echo "$PRIORIDADE" | tr -d '\r')
            DESC=$(echo "$DESC" | tr -d '\r')
            # pula linhas vazias que poderiam quebrar o alinhamento do menu
            if [[ -z "$ID" ]]; then continue; fi

            local COR_PRIORIDADE=""
            case "$PRIORIDADE" in
                ALTA) COR_PRIORIDADE="$COR_VERMELHO" ;;
                MEDIA) COR_PRIORIDADE="$COR_AMARELO" ;;
                BAIXA) COR_PRIORIDADE="$COR_AZUL" ;;
            esac

            if [[ "$STATUS" == "ABERTA" ]]; then
                OPCOES+=("[ ] $(echo -e "${COR_PRIORIDADE}[$PRIORIDADE]${RESET}") $DESC")
            else
                OPCOES+=("[X] $(echo -e "${COR_VERDE}[CONCLUÍDA]${RESET}") $DESC")
            fi
            IDS+=("$ID")
            STATUS_LIST+=("$STATUS")
            PRIORIDADE_LIST+=("$PRIORIDADE")
            DESCRICOES+=("$DESC")
        done < "$ARQ_AFAZERES"

        OPCOES+=("Voltar")

        HABILITAR_DEL=1
        selecionar_menu "${OPCOES[@]}"
        local ESCOLHA=$?

        if [[ $ESCOLHA -eq $(( ${#OPCOES[@]} -1 )) ]]; then
            break
        fi

        local ID_SELECIONADO="${IDS[$ESCOLHA]}"
        local DESC_SELECIONADA="${DESCRICOES[$ESCOLHA]}"

        # lógica do DEL para remover
        if [[ "$ACAO_MENU" == "DEL" ]]; then
            echo
            # confirmação de exclusão com nome da tarefa
            read -rp "Tem certeza que deseja EXCLUIR a tarefa '${DESC_SELECIONADA}'? [s/N]: " CONFIRMACAO
            if [[ "$CONFIRMACAO" =~ ^[sS]$ ]]; then
                local TEMP_TAR
                TEMP_TAR=$(mktemp)
                awk -F '|' -v id="$ID_SELECIONADO" '$1 != id {print $0}' "$ARQ_AFAZERES" > "$TEMP_TAR"
                mv "$TEMP_TAR" "$ARQ_AFAZERES"
            fi
        # lógica do enter para alterar status da tarefa
        elif [[ "$ACAO_MENU" == "ENTER" ]]; then
            local NOVO_STATUS="CONCLUIDA"
            if [[ "${STATUS_LIST[$ESCOLHA]}" == "CONCLUIDA" ]]; then
                NOVO_STATUS="ABERTA"
            fi

            local TEMP_TAR
            TEMP_TAR=$(mktemp)
            awk -F'|' -v id="$ID_SELECIONADO" -v status="$NOVO_STATUS" 'BEGIN {OFS="|"} {
                if ($1 == id) $2 = status; print $0
            }' "$ARQ_AFAZERES" > "$TEMP_TAR"
            mv "$TEMP_TAR" "$ARQ_AFAZERES"
        fi
    done
}

menu_tarefas(){
    while true; do
    
    OPCOES=(
        "Adicionar tarefa"
        "Listar tarefas"
        "Voltar"
    )

    selecionar_menu "${OPCOES[@]}"
    OPCAO=$?
    
    if [[ $OPCAO -eq 255 ]]; then
        return
    fi

        case "$OPCAO" in
        
            0) add_tarefa ;;
            1) ls_tarefas ;;
    
        esac
    done
}
