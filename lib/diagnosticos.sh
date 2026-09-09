#!/bin/bash
# ==========================================
# DIAGNÓSTICOS
# ==========================================

add_diagnostico(){
    clear
    echo
    echo "========== ADICIONAR DIAGNÓSTICO =========="
    echo

    local TITULO TEMP_DIAG DATA_DIAG CABECALHO CONTINUAR CONTEUDO_TESTE CORRIGIR

    read -e -rp "Título: " TITULO
    if [[ -z "$TITULO" ]]; then
        echo
        echo "O título não pode estar vazio"
        read -rp "Pressione ENTER para voltar..."
        sleep 1
        return
    fi    

    TEMP_DIAG=$(mktemp)
    {
    echo "=== O QUE ESTAVA ACONTECENDO ==="
    echo "(escreva aqui)"
    echo
    echo "========== EXPLICAÇÃO =========="
    echo "(escreva aqui)"
    echo
    echo "=========== SOLUÇÃO ============"
    echo "(escreva aqui)"
    } > "$TEMP_DIAG"

    clear
    echo "==============================================================="
    echo "Abrindo editor para preencher o diagnóstico"
    echo "Preencha abaixo de cada seção (NÃO apague os títulos com '===')"
    echo "Ctrl+O para salvar, Ctrl+X para sair"
    read -rp "Pressione ENTER para continuar..."
    
    CONTINUAR="sim"
    while [[ "$CONTINUAR" == "sim" ]]; do
        nano "$TEMP_DIAG"
        CONTINUAR="nao"
        if ! grep -qF "=== O QUE ESTAVA ACONTECENDO ===" "$TEMP_DIAG" || \
        ! grep -qF "========== EXPLICAÇÃO ==========" "$TEMP_DIAG" || \
        ! grep -qF "=========== SOLUÇÃO ============" "$TEMP_DIAG"; then
            echo
            read -rp "Uma ou mais seções foram removidas ou alteradas, deseja reabrir o editor para corrigir? [s/N]: " CORRIGIR
            if [[ ! "$CORRIGIR" =~ ^[nN]$ ]]; then
                CONTINUAR="sim"
            else
                rm -f "$TEMP_DIAG"
                echo
                echo "Diagnóstico descartado"
                read -rp "Pressione ENTER para voltar..."
                return
            fi
            continue
        fi
        CONTEUDO_TESTE=$(sed 's/(escreva aqui)//g' "$TEMP_DIAG")
        local SECAO_ERRO SECAO_EXPLIC SECAO_SOLUC
        SECAO_ERRO=$(echo "$CONTEUDO_TESTE" | sed -n '/=== O QUE ESTAVA ACONTECENDO ===/,/========== EXPLICAÇÃO ==========/p' | sed '1d;$d')
        SECAO_EXPLIC=$(echo "$CONTEUDO_TESTE" | sed -n '/========== EXPLICAÇÃO ==========/,/=========== SOLUÇÃO ============/p' | sed '1d;$d')
        SECAO_SOLUC=$(echo "$CONTEUDO_TESTE" | sed -n '/=========== SOLUÇÃO ============/,$p' | sed '1d')

        if [[ -z "${SECAO_ERRO//[$'\n\r ']/}" ]] || \
           [[ -z "${SECAO_EXPLIC//[$'\n\r ']/}" ]] || \
           [[ -z "${SECAO_SOLUC//[$'\n\r ']/}" ]]; then
            echo
            echo "Uma ou mais seções ficaram vazias"
            read -rp "Deseja reabrir para corrigir? [s/N]: " CORRIGIR
            if [[ "$CORRIGIR" =~ ^[nN]$ ]]; then
                CONTINUAR="sim"
            else
                rm -f "$TEMP_DIAG"
                echo
                echo "Diagnóstico descartado"
                read -rp "Pressione ENTER para voltar..."
                return
            fi
        fi
    done
    DATA_DIAG=$(date '+%d-%m-%Y')
    # remove "(escreva aqui)" se o usuario não remover
    sed -i 's/(escreva aqui)//g' "$TEMP_DIAG"
    CABECALHO=$(mktemp)
    {
        echo "================" 
        echo "Data: $DATA_DIAG"
        echo "Título: $TITULO"
        echo "----------------"
        echo
        cat "$TEMP_DIAG"
        echo
        echo "$SEPARADOR_DIAGNOSTICO"
    } > "$CABECALHO"
    
    cat "$CABECALHO" >> "$ARQ_DIAGNOSTICOS"
    rm -f "$TEMP_DIAG" "$CABECALHO"

    echo
    echo "Diagnóstico salvo com sucesso!"
    read -rp "Pressione ENTER para voltar..."
    clear
}

abrir_diagnostico(){
    local OPCOES
    local TITULOS_ARR=()
    local BLOCOS=()

    while true; do
        clear
        echo "==================================="
        echo "         ABRIR DIAGNÓSTICO"
        echo "==================================="

        if [[ ! -s "$ARQ_DIAGNOSTICOS" ]]; then
            echo "Nenhum diagnóstico cadastrado"
            echo
            read -rp "Pressione ENTER para voltar..."
            return
        fi
        
        OPCOES=()
        TITULOS_ARR=()
        BLOCOS=()

        local BLOCO_ATUAL=""
        while IFS= read -r LINHA || [[ -n "$LINHA" ]]; do
            if [[ "$LINHA" == "$SEPARADOR_DIAGNOSTICO" ]]; then
                if [[ -n "${BLOCO_ATUAL//[$'\n\r ']/}" ]]; then
                    BLOCOS+=("$BLOCO_ATUAL")
                    local TITULO_LINHA
                    TITULO_LINHA=$(echo "$BLOCO_ATUAL" | grep "^Título:" | head -n 1 | sed 's/^Título: //')
                    OPCOES+=("$TITULO_LINHA")
                    TITULOS_ARR+=("$TITULO_LINHA")
                fi
                BLOCO_ATUAL=""
            else
                BLOCO_ATUAL+="$LINHA"$'\n'
            fi
        done < "$ARQ_DIAGNOSTICOS"
        
        OPCOES+=("Voltar")

        HABILITAR_DEL=1
        selecionar_menu "${OPCOES[@]}"
        local ESCOLHA=$?

        if [[ $ESCOLHA -eq $(( ${#OPCOES[@]} - 1 )) ]]; then
            break
        fi
        
        local TITULO_SELECIONADO="${TITULOS_ARR[$ESCOLHA]}"

        if [[ "$ACAO_MENU" == "DEL" ]]; then
            echo
            read -rp "Tem certeza que deseja EXCLUIR o diagnóstico '${TITULO_SELECIONADO}'? [s/N]: " CONFIRMACAO
            if [[ "$CONFIRMACAO" =~ ^[sS]$ ]]; then
                local TEMP_DIAG
                TEMP_DIAG=$(mktemp)
                for i in "${!BLOCOS[@]}"; do
                    if [[ $i -ne "$ESCOLHA" ]]; then
                        printf "%s" "${BLOCOS[$i]}" >> "$TEMP_DIAG"
                        echo "$SEPARADOR_DIAGNOSTICO" >> "$TEMP_DIAG"
                    fi
                done
                mv "$TEMP_DIAG" "$ARQ_DIAGNOSTICOS"
            fi
            continue
        fi

        clear
        echo "==================================="
        echo " DIAGNÓSTICO: $TITULO_SELECIONADO"
        echo "==================================="
        echo
        printf "%s" "${BLOCOS[$ESCOLHA]}"
        echo
        echo "==================================="
        read -rp "Pressione ENTER para voltar à lista..."
    done
}

ls_diagnostico(){
    clear
    echo "==============="
    echo "DIAGNÓSTICOS"

    if [[ ! -s "$ARQ_DIAGNOSTICOS" ]]; then
        echo "Nenhum diagnóstico cadastrado"
    else
        grep -v "^$SEPARADOR_DIAGNOSTICO$" "$ARQ_DIAGNOSTICOS"
    fi

    echo
    read -rp "Pressione ENTER para voltar..."
    clear
}

menu_diagnosticos(){
    while true; do
        clear
        
        local OPCOES
        OPCOES=(
            "Adicionar diagnóstico"
            "Abrir diagnóstico"
            "Listar diagnósticos"
            "Voltar"
        )

        selecionar_menu "${OPCOES[@]}"
        local OPCAO=$?

        if [[ $OPCAO -eq 255 ]]; then
            return
        fi

        case $OPCAO in
            0) add_diagnostico ;;
            1) abrir_diagnostico ;;
            2) ls_diagnostico ;;
        esac
    done
}
