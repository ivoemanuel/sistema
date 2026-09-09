#!/bin/bash
# ==========================================
# FEEDBACK
# ==========================================

gerar_feedback() {

    echo
    echo "========== FEEDBACK =========="
    echo

    if [[ ! -f "$ARQUIVO" ]]; then
        echo "Não existe registro para hoje."
        return
    fi
    
    local USUARIO_LOWER ARQ_FEEDBACK_USUARIO
    USUARIO_LOWER=$(echo "$USUARIO" | tr '[:upper:]' '[:lower:]' )
    ARQ_FEEDBACK_USUARIO="$DIR_FEEDBACK/feedback-${USUARIO_LOWER}.txt"

    # Verifica se já existe um feedback de hoje
    if [[ ! -f "$ARQ_FEEDBACK_USUARIO" ]] || ! grep -q "^DATA: $DATA$" "$ARQ_FEEDBACK_USUARIO"; then

        {
            echo "DATA: $DATA"
            echo "USUARIO: $USUARIO"
            echo
            echo "Boa noite, pessoal! Segue o feedback do dia de hoje: ($DATA)"
            echo

            grep '| S |' "$ARQUIVO" | while IFS='|' read -r HORA CATEGORIA MARCADOR ATIVIDADE; do
                ATIVIDADE=$(echo "$ATIVIDADE" | sed 's/^ *//')
                echo "- $ATIVIDADE"
            done

            echo
            echo "Bom descanso a todos! 🧬"

        } > "$ARQ_FEEDBACK_USUARIO"
    fi

    while true; do

        clear

        echo "========== FEEDBACK =========="
        echo
        cat "$ARQ_FEEDBACK_USUARIO"
        echo

        read -rp "Deseja adicionar algo ao feedback? [s/N]: " ADICIONAR

        if [[ "$ADICIONAR" =~ ^[Ss]$ ]]; then

            clear

            echo
            echo "Digite o que deseja adicionar."
            echo "Digite FIM em uma linha separada quando terminar."
            echo

            ADICIONAL=""

            while true; do
                read -r LINHA

                if [[ "$LINHA" == "FIM" ]]; then
                    break
                fi

                ADICIONAL+="$LINHA"$'\n'
            done

            if [[ -n "${ADICIONAL//[$'\n\r ']/}" ]]; then

                TEMP=$(mktemp)

                # Remove a frase final e a linha vazia anterior
                sed '$d' "$ARQ_FEEDBACK_USUARIO" | sed '$d' > "$TEMP"

                # Adiciona cada linha como um novo item
                while IFS= read -r LINHA; do
                    if [[ -n "${LINHA//[$'\r ']/}" ]]; then
                        echo "- $LINHA" >> "$TEMP"
                    fi
                done <<< "$ADICIONAL"

                # Adiciona novamente a frase final
                echo >> "$TEMP"
                echo "Bom descanso a todos! 🧬" >> "$TEMP"

                mv "$TEMP" "$ARQ_FEEDBACK_USUARIO"
            fi

            continue
        fi

        break

    done

    clear

    echo "========== FEEDBACK =========="
    echo
    cat "$ARQ_FEEDBACK_USUARIO"

    echo
    read -rp "Pressione ENTER para voltar ao menu..."
}


editar_feedback() {

    local USUARIO_LOWER ARQ_FEEDBACK_USUARIO
    USUARIO_LOWER=$(echo "$USUARIO" | tr '[:upper:]' '[:lower:]' )
    ARQ_FEEDBACK_USUARIO="$DIR_FEEDBACK/feedback-${USUARIO_LOWER}.txt"

    if [[ ! -f "$ARQ_FEEDBACK_USUARIO" ]]; then
        echo
        echo "Ainda não existe um feedback para editar."
        read -rp "Pressione ENTER para voltar..."
        return
    fi

    nano "$ARQ_FEEDBACK_USUARIO"
}

enviar_feedback_wpp() {
    local OPCOES ARQUIVOS_ENCONTRADOS NOME_ARQUIVO ESCOLHA
    local CONTEUDO_FEEDBACK TEXTO_CODIFICADO LINK_GRUPO

    while true; do
        clear
        echo "========== ENVIAR FEEDBACK VIA WHATSAPP =========="
        echo

        if ! ls "$DIR_FEEDBACK"/feedback-*.txt >/dev/null 2>&1; then
            echo
        fi

        OPCOES=()
        ARQUIVOS_ENCONTRADOS=()
        while IFS= read -r NOME_ARQUIVO; do
            if [[ -z "$NOME_ARQUIVO" ]]; then continue; fi
            OPCOES+=("$(basename "$NOME_ARQUIVO" .txt)")
            ARQUIVOS_ENCONTRADOS+=("$NOME_ARQUIVO")
        done < <(find "$DIR_FEEDBACK" -maxdepth 1 -type f -name "feedback-*.txt" | sort)

        OPCOES+=("Voltar")
        selecionar_menu "${OPCOES[@]}"
        
        ESCOLHA="$?"
        if [[ "$ESCOLHA" -eq $(( ${#OPCOES[@]} - 1 )) ]]; then
            break
        fi

        CONTEUDO_FEEDBACK=$(cat "${ARQUIVOS_ENCONTRADOS[$ESCOLHA]}")
        TEXTO_CODIFICADO=$(url_encode "$CONTEUDO_FEEDBACK")
        LINK_GRUPO="https://wa.me/?text=${TEXTO_CODIFICADO}"

        clear
        echo "Link gerado, abrindo no navegador padrão..."
        echo "Escolha a conversa ou grupo de destino no WhatsApp"
        echo
        echo "Se não abrir automaticamente, copie o link abaixo:"
        echo "$LINK_GRUPO"
        echo

        xdg-open "$LINK_GRUPO" >/dev/null 2>&1 &

        read -rp "Pressione ENTER para voltar..."
    done
}

menu_feedback() {
    while true; do
        clear

        local OPCOES
        OPCOES=(
            "Gerar feedback"
            "Editar feedback"
            "Enviar feedback via WhatsApp"
            "Voltar"
        )

        selecionar_menu "${OPCOES[@]}"
        
        ESCOLHA=$?
        case "$ESCOLHA" in
            0) gerar_feedback ;;
            1) editar_feedback ;;
            2) enviar_feedback_wpp ;;
            3) break ;;
        esac
    done
}
