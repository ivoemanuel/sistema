#!/bin/bash
# ==========================================
# ARTIGOS
# ==========================================

adicionar_artigo(){
    clear
    echo
    echo "========== ADICIONAR ARTIGO =========="
    echo

    local TITULO LINK ID

    read -e -rp "Título: " TITULO
    read -e -rp "Link: " LINK

    if [[ -z "$TITULO" || -z "$LINK" ]]; then
        echo
        echo "Título e link não podem estar vazios."
        return
    fi

    if [[ ! -s "$ARQ_ARTIGOS" ]]; then
        ID=1
    else
        ID=$(awk -F'|' 'NF >= 1 {print $1}' "$ARQ_ARTIGOS" | sort -n | tail -n 1)
        ID=$((ID + 1))
    fi

    echo "$ID|$TITULO|$LINK" | sudo tee -a "$ARQ_ARTIGOS" > /dev/null
    
    echo
    echo "======================================"
    echo "Artigo adicionado com sucesso!"
    read -rp "Pressione ENTER para voltar..."
}

listar_artigos() {
    local OPCOES
    local TITULOS
    local LINKS
    local IDS

    while true; do
        clear
        echo
        echo "========== NÃO ACREDITE EM MIM... PESQUISE! =========="
        echo

        if [[ ! -s "$ARQ_ARTIGOS" ]]; then
            echo "Nenhum artigo cadastrado."
            sleep 2
            return
        fi

        OPCOES=()
        TITULOS=()
        LINKS=()
        IDS=()

        while IFS="|" read -r ID TITULO LINK; do
            if [[ -z "$ID" ]]; then continue; fi
            OPCOES+=("$TITULO")
            TITULOS+=("$TITULO")
            LINKS+=("$LINK")
            IDS+=("$ID")
        done < <(sort -n "$ARQ_ARTIGOS")

        OPCOES+=("Voltar")

        HABILITAR_DEL=1
        selecionar_menu "${OPCOES[@]}"
        local ESCOLHA=$?

        if [[ $ESCOLHA -eq $(( ${#OPCOES[@]} - 1 )) ]]; then
            break
        fi

        local ID_SELECIONADO="${IDS[$ESCOLHA]}"
        local TITULO_SELECIONADO="${TITULOS[$ESCOLHA]}"

        if [[ "$ACAO_MENU" == "DEL" ]]; then
            echo
            read -rp "Tem certeza que deseja EXCLUIR o artigo '${TITULO_SELECIONADO}'? [s/N]: " CONFIRMACAO
            if [[ "$CONFIRMACAO" =~ ^[sS]$ ]]; then
                local TEMP_ART
                TEMP_ART=$(mktemp)
                awk -F '|' -v id="$ID_SELECIONADO" '$1 != id {print $0}' "$ARQ_ARTIGOS" > "$TEMP_ART"
                mv "$TEMP_ART" "$ARQ_ARTIGOS"
            fi
            continue # reinicia o loop para não abrir o artigo apagado
        fi

        clear
        echo "========== DETALHES DO ARTIGO =========="
        echo "Título: ${TITULOS[$ESCOLHA]}"
        echo "Link:   ${LINKS[$ESCOLHA]}"
        echo "========================================"
        read -rp "Pressione ENTER para voltar à lista..."
    done
}

pesquisar_artigo(){
    clear
    echo
    echo "========== BUSCAR ARTIGO =========="
    echo

    local PESQUISA

    read -e -rp "Digite o título ou palavra-chave: " PESQUISA

    if [[ -z "$PESQUISA" ]]; then
        echo
        echo "Pesquisa vazia."
        echo
        sleep 2
        return
    fi

    while true; do
        clear
        echo
        echo "========== RESULTADOS DA BUSCA =========="
        echo

        local OPCOES=()
        local TITULOS=()
        local LINKS=()
        local ENCONTRADOS=0

        # filtra direto no grep e constrói o array com os resultados
        while IFS="|" read -r ID TITULO LINK; do
            OPCOES+=("$TITULO")
            TITULOS+=("$TITULO")
            LINKS+=("$LINK")
            ((ENCONTRADOS++))
        done < <(grep -i "$PESQUISA" "$ARQ_ARTIGOS")

        if [[ $ENCONTRADOS -eq 0 ]]; then
            echo
            echo "Nenhum artigo encontrado para a pesquisa: $PESQUISA"
            sleep 2
            return
        fi
    
        OPCOES+=("Voltar")

        selecionar_menu "${OPCOES[@]}"
        local ESCOLHA=$?

        if [[ $ESCOLHA -eq $(( ${#OPCOES[@]} - 1 )) ]]; then
            break
        fi

        clear
        echo "========== DETALHES DO ARTIGO =========="
        echo "Título: ${TITULOS[$ESCOLHA]}"
        echo "Link:   ${LINKS[$ESCOLHA]}"
        echo "========================================"
        read -rp "Pressione ENTER para voltar à busca..."
    done

}

menu_artigos() {
    while true; do
        clear
        
        OPCOES=(
            "Adicionar artigo"
            "Listar artigos"
            "Buscar artigo"
        )

        selecionar_menu "${OPCOES[@]}" 
        OPCAO=$?

        if [[ $OPCAO -eq 255 ]]; then
            return
        fi

        case $OPCAO in
            0) adicionar_artigo ;;
            1) listar_artigos ;;
            2) pesquisar_artigo ;;
        esac
    done
}
