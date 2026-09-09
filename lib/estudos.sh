#!/bin/bash
# ==========================================
# ESTUDOS/EXPLICAÇÕES
# ==========================================

nova_explicacao(){
    clear
    echo
    echo "========== EXPLICAÇÃO =========="
    echo

    local TITULO CONTEUDO LINHA NOME ARQUIVO_EXPLICACAO TEMP_EXP DATA_EXP

    read -e -rp "Título: " TITULO

    if [[ -z "$TITULO" ]]; then
        echo
        echo "O título não pode estar vazio"
        sleep 2
        return
    fi

    TEMP_EXP=$(mktemp)
    clear
    echo
    echo "Abrindo editor para digitar o conteúdo da explicação"
    echo "Ctrl+O para salvar, Ctrl+X para sair"
    read -rp "Pressione ENTER para continuar..."
    echo

    nano "$TEMP_EXP"
    CONTEUDO=$(cat "$TEMP_EXP")
    rm -f "$TEMP_EXP"

    if [[ -z "$CONTEUDO" ]]; then
        echo
        echo "O conteúdo não pode estar vazio"
        read -rp "Pressione ENTER para voltar..."
        return
    fi
    
    NOME=$(echo "$TITULO" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
    DATA_EXP=$(date '+%d-%m-%Y')
    ARQUIVO_EXPLICACAO="$DIR_EXPLICACOES/${DATA_EXP}-${NOME}.txt"

    {
        echo "========================================="
        echo "               EXPLICAÇÃO"
        echo "========================================="
        echo
        echo "TÍTULO: $TITULO"
        echo "DATA: $DATA_EXP"
        echo "USUÁRIO: $USUARIO"
        echo
        echo "========================================="
        echo
        printf "%s" "$CONTEUDO"
        echo
    } > "$ARQUIVO_EXPLICACAO"

    echo
    echo "Anotação salva com sucesso!"
    echo "Arquivo: $ARQUIVO_EXPLICACAO"
    read -rp "Pressione ENTER para voltar..."
}

abrir_explicacao(){
    local OPCOES
    local ARQUIVOS_ENCONTRADOS
    local ARQUIVOS ARQUIVO_ATUAL TITULO

    while true; do
        clear
        echo
        echo "========== ABRIR EXPLICAÇÃO =========="
        echo

        ARQUIVOS=$(find "$DIR_EXPLICACOES" -maxdepth 1 -type f -name "*.txt" | sort)

        if [[ -z "$ARQUIVOS" ]]; then
            echo
            echo "Nenhuma explicação cadastrada"
            sleep 2
            return
        fi

        OPCOES=()
        ARQUIVOS_ENCONTRADOS=()

        while IFS= read -r ARQUIVO_ATUAL; do
            if [[ -z "$ARQUIVO_ATUAL" ]]; then continue; fi
            TITULO=$(grep "^TÍTULO:" "$ARQUIVO_ATUAL" | sed 's/^TÍTULO: //')
            OPCOES+=("$TITULO")
            ARQUIVOS_ENCONTRADOS+=("$ARQUIVO_ATUAL")
        done <<< "$ARQUIVOS"

        OPCOES+=("Voltar")

        HABILITAR_DEL=1
        selecionar_menu "${OPCOES[@]}"
        local ESCOLHA=$?

        if [[ $ESCOLHA -eq $(( ${#OPCOES[@]} - 1 )) ]]; then
            break
        fi

        local TITULO_SELECIONADO="${OPCOES[$ESCOLHA]}"

        if [[ "$ACAO_MENU" == "DEL" ]]; then
            echo
            read -rp "Tem certeza que deseja EXCLUIR a explicação '${TITULO_SELECIONADO}'? [s/N]: " CONFIRMACAO
            if [[ "$CONFIRMACAO" =~ ^[sS]$ ]]; then
                rm -f "${ARQUIVOS_ENCONTRADOS[$ESCOLHA]}"
            fi
            continue # reinicia o loop para atualizar a lista
        fi

        clear
        echo
        cat "${ARQUIVOS_ENCONTRADOS[$ESCOLHA]}"
        echo
        echo "========================================="
        read -rp "Pressione ENTER para voltar à lista..."
    done
}

pesquisar_explicacao(){
    clear
    echo
    echo "========== PESQUISAR EXPLICAÇÃO =========="
    echo

    local PESQUISA ARQUIVO_ATUAL TITULO DATA_EXPLICACAO

    read -e -rp "Digite o título ou a palavra-chave: " PESQUISA

    if [[ -z "$PESQUISA" ]]; then
        echo
        echo "A Pesquisa não pode estar vazia."
        read -rp "Pressione ENTER para voltar..."
        return
    fi

    local OPCOES=()
    local ENCONTRADOS=0
    local ARQUIVOS_ENCONTRADOS=()

    # busca e preenchimento dos arrays
    while IFS= read -r ARQUIVO_ATUAL; do        
        if grep -qi "$PESQUISA" "$ARQUIVO_ATUAL"; then
            TITULO=$(grep "^TÍTULO:" "$ARQUIVO_ATUAL" | sed 's/^TÍTULO: //')
            DATA_EXPLICACAO=$(grep "^DATA:" "$ARQUIVO_ATUAL" | sed 's/^DATA: //')

            # add o título formatado no menu interativo
            OPCOES+=("$TITULO (Data: $DATA_EXPLICACAO)")

            ARQUIVOS_ENCONTRADOS+=("$ARQUIVO_ATUAL")   
            ((ENCONTRADOS++))
        fi
    done < <(find "$DIR_EXPLICACOES" -maxdepth 1 -type f -name "*.txt" | sort)

    if [[ $ENCONTRADOS -eq 0 ]]; then
        echo
        echo "Nenhuma explicação encontrada para: $PESQUISA"
        sleep 2
    fi
    # add a opção voltar
    OPCOES+=("Voltar")

    while true; do
        selecionar_menu "${OPCOES[@]}"
        local ESCOLHA=$?

        if [[ $ESCOLHA -eq $(( ${#OPCOES[@]} - 1)) ]]; then
            break
        fi

        clear
        echo
        cat "${ARQUIVOS_ENCONTRADOS[$ESCOLHA]}"
        echo
        echo "========================================"
        read -rp "Pressione ENTER para voltar aos resultados..."
    done
}

menu_estudos(){
    while true; do
        clear
       
        OPCOES=(
         "Nova explicação"
         "Abrir explicação"
         "Pesquisar explicações"
         "Voltar"
        
	)
        
        selecionar_menu "${OPCOES[@]}"
        OPCAO=$?

        if [[ $OPCAO -eq 255 ]]; then
            return
        fi

        case $OPCAO in
        
            0) nova_explicacao ;;
            1) abrir_explicacao ;;
            2) pesquisar_explicacao ;;
        esac
    done
}
