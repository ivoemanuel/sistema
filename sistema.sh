#!/bin/bash
# ==========================================
# CONFIGURAÇÕES
# ==========================================

RAIZ="/opt/sistema"

DIR_REGISTROS="$RAIZ/registros"
DIR_ARTIGOS="$RAIZ/artigos"
DIR_EXPLICACOES="$RAIZ/explicacoes"
DIR_DIAGNOSTICOS="$RAIZ/diagnosticos"
DIR_AFAZERES="$RAIZ/afazeres"
DIR_FEEDBACK="$RAIZ/feedback"
DIR_CHEATSHEET="$RAIZ/cheat-sheet"
DIR_IPS="$RAIZ/ips"
DIR_INSTRUCOES="$RAIZ/instrucoes"

ARQ_ARTIGOS="$DIR_ARTIGOS/artigos.txt"
ARQ_DIAGNOSTICOS="$DIR_DIAGNOSTICOS/diagnosticos.txt"
ARQ_AFAZERES="$DIR_AFAZERES/afazeres.txt"
ARQ_USUARIOS="$DIR_FEEDBACK/usuarios.txt"
ARQ_CHEATSHEET="$DIR_CHEATSHEET/comandos.txt"
ARQ_IPS="$DIR_IPS/ips.txt"
ARQ_VIZINHOS="$DIR_IPS/vizinhos.txt"

SEPARADOR_DIAGNOSTICO="###FIM_DIAGNOSTICO###"

USUARIO=$(whoami)
DATA=$(date '+%d-%m-%Y')
HORA=$(date '+%H:%M')

ARQUIVO="$DIR_REGISTROS/$DATA.txt"

umask 002

# ==========================================
# VERIFICAR E CRIAR ESTRUTURA
# ==========================================

verificar_estrutura() {
    # Pastas
    mkdir -p "$DIR_REGISTROS"
    mkdir -p "$DIR_EXPLICACOES"
    mkdir -p "$DIR_ARTIGOS"
    mkdir -p "$DIR_DIAGNOSTICOS"
    mkdir -p "$DIR_AFAZERES"
    mkdir -p "$DIR_FEEDBACK"
    mkdir -p "$DIR_CHEATSHEET"
    mkdir -p "$DIR_IPS"
    mkdir -p "$DIR_INSTRUCOES"
    # Arquivos
    touch "$ARQ_ARTIGOS"
    touch "$ARQ_AFAZERES"
    touch "$ARQ_DIAGNOSTICOS"
    touch "$ARQ_USUARIOS"
    touch "$ARQ_CHEATSHEET"
    touch "$ARQ_IPS"
    # add $USUARIO=user em usuarios.txt para o feedback ficar com o nome da pessoa, para isso teremos que mudar 'user' para o nome que queremos que apareça
    if ! grep -q "^${USUARIO}=" "$ARQ_USUARIOS" 2>/dev/null; then
        echo "${USUARIO}=user" >> "$ARQ_USUARIOS"
    fi
}

# ==========================================
# SENHAS
# ==========================================

COFRE_ARQUIVO="$RAIZ/.cofre.enc"
PALAVRA_SECRETA="s#ad0w"

verificar_palavra_secreta() {
    local tecla="$1"
    local n=${#PALAVRA_SECRETA}
    [[ "$tecla" =~ [[:print:]] ]] || return 1

    BUFFER_TECLAS+="$tecla"
    (( ${#BUFFER_TECLAS} > n )) && BUFFER_TECLAS="${BUFFER_TECLAS: -n}"

    if [[ "$BUFFER_TECLAS" == "$PALAVRA_SECRETA" ]]; then
        BUFFER_TECLAS=""
        abrir_cofre_senhas
        return 0
    fi
    return 1
}

abrir_cofre_senhas() {
    local senha_master
    local tmp

    clear
    echo ""
    echo

    if [[ ! -f "$COFRE_ARQUIVO" ]]; then

        read -rp "Nenhum cofre encontrado. Criar um novo? (s/n) " resp

        if [[ "$resp" != "s" ]]; then
            read -rp "Press ENTER" _
            return
        fi

        echo
        read -rsp "Crie sua senha mestra: " senha_master
        echo

        read -rsp "Confirme sua senha mestra: " senha_confirmacao
        echo

        if [[ "$senha_master" != "$senha_confirmacao" ]]; then
            echo "As senhas não coincidem."
            sleep 2
            return
        fi

        criar_cofre_senhas "$senha_master"

        read -rp "Press ENTER" _
        return
    fi

    # COFRE JÁ EXISTE
    read -rsp "" senha_master
    echo

    tmp=$(mktemp)

    # DESCRIPTOGRAFA
    if ! openssl enc -d -aes-256-cbc -pbkdf2 \
        -in "$COFRE_ARQUIVO" \
        -out "$tmp" \
        -pass pass:"$senha_master" 2>/dev/null; then

        echo "Senha incorreta ou arquivo corrompido."
        rm -f "$tmp"
        return
    fi

    # ABRE NO NANO
    nano "$tmp"

    # CRIPTOGRAFA NOVAMENTE APÓS SAIR DO NANO
    if openssl enc -aes-256-cbc -pbkdf2 -salt \
        -in "$tmp" \
        -out "$COFRE_ARQUIVO" \
        -pass pass:"$senha_master"; then

        chmod 600 "$COFRE_ARQUIVO"
    else
        echo "Erro ao salvar o cofre."
        sleep 2
    fi

    # APAGA O ARQUIVO TEMPORÁRIO
    shred -u "$tmp" 2>/dev/null || rm -f "$tmp"

    return
}

criar_cofre_senhas() {
    local senha_master="$1" tmp
    tmp=$(mktemp)
    echo "Digite o conteúdo do cofre (Ctrl+D para terminar):"
    cat > "$tmp"
    mkdir -p "$(dirname "$COFRE_ARQUIVO")"
    openssl enc -aes-256-cbc -pbkdf2 -salt -in "$tmp" -out "$COFRE_ARQUIVO" \
        -pass pass:"$senha_master"
    shred -u "$tmp" 2>/dev/null || rm -f "$tmp"
    echo "Cofre criado em $COFRE_ARQUIVO"
}

# ==========================================
# MENU DE NAVEGAÇÂO
# ==========================================

selecionar_menu() {
    local COR_DESTAQUE="\e[48;2;138;43;226m" RESET="\e[0m" 
    local OPCOES=("$@")
    local SELECIONADO=0 
    local TECLA RETORNO
    local BUFFER_TECLAS=""
    ACAO_MENU="ENTER"

    while true; do
        clear

        # Imprime o cabeçalho/contexto antes do menu, caso a variável tenha sido setada
        if [[ -n "$MENSAGEM_MENU" ]]; then
            echo -e "$MENSAGEM_MENU"
        fi

        for i in "${!OPCOES[@]}"; do
            local cor_opcao="${CORES_MENU[$i]:-}"
            if [[ $i -eq $SELECIONADO ]]; then
                echo -e "${COR_DESTAQUE} 🐧 ${OPCOES[$i]} ${RESET}"
            else
                echo -e "  ${cor_opcao}${OPCOES[$i]}${RESET}"
            fi
        done

        dica="↑ ↓ navegar | ENTER selecionar | BACKSPACE voltar"
        [[ "$HABILITAR_DEL" == "1" ]] && dica+=" | DEL remover"
        [[ "$HABILITAR_ADD" == "1" ]] && dica+=" | + adicionar"
        echo
        echo -e "$dica"

        IFS= read -rsn1 TECLA

        # BACKSPACE
        if [[ "$TECLA" == $'\x7f' || "$TECLA" == $'\x08' ]]; then
            RETORNO=255
            break
        fi

        # '+' (adicionar)
        if [[ "$TECLA" == "+" && "$HABILITAR_ADD" == "1" ]]; then
            RETORNO=254
            break
        fi

        # ENTER
        if [[ "$TECLA" == "" ]]; then
            RETORNO=$SELECIONADO
            break
        fi

        # SETAS / DELETE
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
                            RETORNO=$SELECIONADO
                            break
                        fi
                    fi 
                    ;;
            esac
        else
            verificar_palavra_secreta "$TECLA"
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
    HABILITAR_ADD=0
    MENSAGEM_MENU=""
    CORES_MENU=()
    
    return "$RETORNO"
}

# ==========================================
# CRIAR ARQUIVO DO DIA
# ==========================================

criar_registro() {

    DATA=$(date '+%d-%m-%Y')
    HORA=$(date '+%H:%M')

    if [ ! -f "$ARQUIVO" ]; then
        {
            echo "========================================"
            echo "           REGISTRO DE TURNOS"
            echo "========================================"
            echo
            echo "DATA: $DATA"
            echo "USUARIO: $USUARIO"
            echo "INICIO: $HORA"
            echo
            echo "========================================"
        } > "$ARQUIVO"
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
            read -rp "Press ENTER"
            return
        fi

        HABILITAR_DEL=1
        selecionar_menu "${OPCOES[@]}"
        ESCOLHA=$?

        if [[ $ESCOLHA -eq 255 ]]; then
            return
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
            read -rp "Press ENTER"
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
            read -rp "Press ENTER"
            continue
        fi

        echo
        read -rp "Confirma salvar essa alteração? [s/N]: " CONFIRMACAO
        if [[ ! "$CONFIRMACAO" =~ ^[sS]$ ]]; then
            echo
            echo "Alteração cancelada"
            read -rp "Press ENTER"
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
        read -rp "Press ENTER"
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
    )

    local TIPO CATEGORIA ATIVIDADE MARCADOR FEEDBACK USUARIO_LOWER ARQ_FEEDBACK_USUARIO

    selecionar_menu "${OPCOES[@]}"
    local TIPO=$?

    if [[ $TIPO -eq 255 ]]; then
        return
    fi

    case $TIPO in
        0) CATEGORIA="ROTINA" ;;
        1) CATEGORIA="ALTERACOES" ;;
        2) CATEGORIA="ARTIGOS" ;;
        3) CATEGORIA="EXPLICACOES" ;;
        4) CATEGORIA="PROBLEMAS" ;;
        5) CATEGORIA="OBSERVACOES" ;;
    esac
    echo
    read -e -rp "Descreva o que foi feito: " ATIVIDADE

    if [ -z "$ATIVIDADE" ]; then
        echo
        echo "A atividade não pode estar vazia."
        read -rp "Press ENTER"
        return
    fi

    HORA=$(date '+%H:%M')

    read -rp "Deseja incluir no feedback? [s/N]:" FEEDBACK

    if [[ "$FEEDBACK" =~ ^[sS]$ ]]; then
        MARCADOR="S"
    else
        MARCADOR="N"
    fi

    echo "[$HORA] | $CATEGORIA | $MARCADOR | $USUARIO | $ATIVIDADE" >> "$ARQUIVO"

    if [[ "$MARCADOR" == "S" ]]; then
        USUARIO_LOWER=$(echo "$USUARIO" | tr '[:upper:]' '[:lower:]')
        ARQ_FEEDBACK_USUARIO="$DIR_FEEDBACK/feedback-${USUARIO_LOWER}.txt"
        cabecalho_feedback "$ARQ_FEEDBACK_USUARIO"
        echo "- $ATIVIDADE" >> "$ARQ_FEEDBACK_USUARIO"
    fi

    echo
    echo "Atividade registrada com sucesso!"
    echo
    read -rp "Press ENTER"

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
    read -rp "Press ENTER"
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
            read -rp "Press ENTER"
            return
        fi

        OPCOES=() # zera a cada volta
        ARQUIVOS_ENCONTRADOS=()

        while IFS= read -r NOME_ARQUIVO; do
            if [[ -z "$NOME_ARQUIVO" ]]; then continue; fi
            OPCOES+=("$(basename "$NOME_ARQUIVO" .txt)")
            ARQUIVOS_ENCONTRADOS+=("$NOME_ARQUIVO")
        done < <(ls -1 "$DIR_REGISTROS"/*.txt | sort -r)

        selecionar_menu "${OPCOES[@]}"
        ESCOLHA=$?

        if [[ $ESCOLHA -eq 255 ]]; then
            return
        fi

        clear
        echo "========================================"
        echo "  REGISTRO: ${OPCOES[$ESCOLHA]}"
        echo "========================================"
        echo
        cat "${ARQUIVOS_ENCONTRADOS[$ESCOLHA]}"
        echo
        echo "========================================"
        read -rp "Press ENTER para voltar ao histórico..."
    done
}

resumo_turno() {
    clear
    echo "========== RESUMO DO TURNO =========="
    echo

    if [[ ! -f "$ARQUIVO" ]] || ! grep -q "|" "$ARQUIVO"; then
        echo "Nenhuma atividade registrada ainda hoje"
        echo
        read -rp "Press ENTER"
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
    read -rp "Press ENTER"
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
        )

        selecionar_menu "${OPCOES[@]}"

        local ESCOLHA="$?"
        
        if [[ $ESCOLHA -eq 255 ]]; then
            return
        fi
        
        case "$ESCOLHA" in
            0) mostrar_ultimo_turno ;;
            1) mostrar_hoje ;;
            2) mostrar_historico ;;
            3) resumo_turno ;;
        esac
    done
}

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

    echo "$ID|$TITULO|$LINK" >> "$ARQ_ARTIGOS"
    
    echo
    echo "======================================"
    echo "Artigo adicionado com sucesso!"
    read -rp "Press ENTER"
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

        HABILITAR_DEL=1
        HABILITAR_ADD=1
        selecionar_menu "${OPCOES[@]}"
        local ESCOLHA=$?

        if [[ $ESCOLHA -eq 255 ]]; then
            return
        fi

        if [[ $ESCOLHA -eq 254 ]]; then
            adicionar_artigo
            continue
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
        read -rp "Press ENTER para voltar à lista..."
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

        selecionar_menu "${OPCOES[@]}"
        local ESCOLHA=$?

        if [[ $ESCOLHA -eq 255 ]]; then
            return
        fi

        clear
        echo "========== DETALHES DO ARTIGO =========="
        echo "Título: ${TITULOS[$ESCOLHA]}"
        echo "Link:   ${LINKS[$ESCOLHA]}"
        echo "========================================"
        read -rp "Press ENTER para voltar à busca..."
    done

}

menu_artigos() {
    while true; do
        clear
        local OPCOES=(
            "Listar artigos"
            "Buscar artigo"
        )

        selecionar_menu "${OPCOES[@]}" 
        
        local OPCAO=$?
        
        if [[ $OPCAO -eq 255 ]]; then
            return
        fi
        
        case $OPCAO in
            0) listar_artigos ;;
            1) pesquisar_artigo ;;
        esac
    done
}

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
    read -rp "Press ENTER para brir o nano"
    echo

    nano "$TEMP_EXP"
    CONTEUDO=$(cat "$TEMP_EXP")
    rm -f "$TEMP_EXP"

    if [[ -z "$CONTEUDO" ]]; then
        echo
        echo "O conteúdo não pode estar vazio"
        read -rp "Press ENTER "
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
    read -rp "Press ENTER "
}

abrir_explicacao(){
    local OPCOES
    local ARQUIVOS_ENCONTRADOS
    local ARQUIVOS ARQUIVO_ATUAL TITULO

    while true; do
        clear
        echo
        echo "========== LISTAR EXPLICAÇÕES =========="
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

        HABILITAR_DEL=1
        HABILITAR_ADD=1
        selecionar_menu "${OPCOES[@]}"
        local ESCOLHA=$?

        if [[ $ESCOLHA -eq 255 ]]; then
            return
        fi

        if [[ $ESCOLHA -eq 254 ]]; then
            nova_explicacao
            continue
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
        read -rp "Press ENTER para voltar à lista..."
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
        read -rp "Press ENTER "
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

    while true; do
        selecionar_menu "${OPCOES[@]}"
        local ESCOLHA=$?

        if [[ $ESCOLHA -eq 255 ]]; then
            return
        fi

        clear
        echo
        cat "${ARQUIVOS_ENCONTRADOS[$ESCOLHA]}"
        echo
        echo "========================================"
        read -rp "Press ENTER para voltar aos resultados..."
    done
}

menu_estudos(){
    while true; do
        clear
        local OPCOES=(
            "Listar explicações"
            "Pesquisar explicações"
	    )
        
        selecionar_menu "${OPCOES[@]}"
        
        local OPCAO=$?

        if [[ $OPCAO -eq 255 ]]; then
            return
        fi

        case $OPCAO in
            0) abrir_explicacao ;;
            1) pesquisar_explicacao ;;
        esac
    done
}

# ==========================================
# TAREFAS
# ==========================================

LARG_TAREFA=30
LARG_PRIORIDADE=11
LARG_PRAZO=10

COR_VERDE="\e[38;5;46m"
COR_AMARELO="\e[38;2;255;255;0m"
COR_VERMELHO="\e[38;2;255;0;0m"
COR_AZUL="\e[38;2;0;191;255m"
COR_CINZA="\e[38;5;245m"
COR_SEL="\e[7m"     # inverte fundo/texto na linha selecionada
RESET="\e[0m"

COR_EMANUEL="\e[38;2;42;57;176;01m"
COR_RAYSSA="\e[38;2;255;20;147;01m"
COR_DANIELE="\e[38;2;148;0;211;01m"

# --------------------- Funções auxiliares ---------------------

normalizar_nfc() {
    # normalizar_nfc "texto" -> mesmo texto, com acentos combinantes
    # convertidos para forma pré-composta (NFC), evitando desalinhamento
    # de tabelas causado por contagem de caracteres divergente
    local texto="$1"
    python3 -c "
import sys, unicodedata
print(unicodedata.normalize('NFC', sys.argv[1]), end='')
" "$texto"
}

repetir() {
    # repetir <quantidade> <caractere-utf8>  (evita 'tr', que quebra multibyte)
    local n="$1" ch="$2" out=""
    for (( k=0; k<n; k++ )); do out+="$ch"; done
    printf '%s' "$out"
}

centralizar() {
    # centralizar "texto" largura
    local LC_ALL=pt_BR.utf8
    local texto="$1" largura="$2" len esq dir
    len=${#texto}
    if (( len >= largura )); then
        printf '%s' "${texto:0:largura}"
        return
    fi
    local total=$(( largura - len ))
    esq=$(( total / 2 ))
    dir=$(( total - esq ))
    printf '%*s%s%*s' "$esq" '' "$texto" "$dir" ''
}

preencher_direita() {
    # preencher_direita "texto" largura  -> como printf "%-Ns", mas seguro p/ UTF-8
    local LC_ALL=pt_BR.utf8
    local texto="$1" largura="$2" falta
    falta=$(( largura - ${#texto} ))
    (( falta < 0 )) && falta=0
    printf '%s%*s' "$texto" "$falta" ''
}

truncar_esq() {
    # truncar_esq "texto" largura  -> alinhado à esquerda, com "…" se estourar
    local LC_ALL=pt_BR.utf8
    local texto="$1" largura="$2" falta
    if (( ${#texto} > largura )); then
        printf '%s' "${texto:0:$((largura-1))}…"
    else
        falta=$(( largura - ${#texto} ))
        (( falta < 0 )) && falta=0
        printf '%s%*s' "$texto" "$falta" ''
    fi
}

calcular_larguras() {
    local LC_ALL=pt_BR.utf8
    local total=${#IDS[@]}
    local i TEXTO LEN

    LARG_TAREFA=6        # tamanho do cabeçalho "TAREFA"
    LARG_PRIORIDADE=10   # tamanho do cabeçalho "PRIORIDADE"
    LARG_PRAZO=5         # tamanho do cabeçalho "PRAZO"

    for (( i = 0; i < total; i++ )); do
        TEXTO=$(printf '#%02d %s' "${IDS[$i]}" "${DESCRICOES[$i]}")
        LEN=${#TEXTO}
        (( LEN > LARG_TAREFA )) && LARG_TAREFA=$LEN

        LEN=${#PRIORIDADE_LIST[$i]}
        (( LEN > LARG_PRIORIDADE )) && LARG_PRIORIDADE=$LEN

        if [[ "${STATUS_LIST[$i]}" == "CONCLUIDA" ]]; then
            LEN=6
        else
            LEN=${#PRAZO_LIST[$i]}
        fi
        (( LEN > LARG_PRAZO )) && LARG_PRAZO=$LEN
    done

    (( LARG_TAREFA < 20 )) && LARG_TAREFA=20
    (( LARG_TAREFA > 60 )) && LARG_TAREFA=60
    (( LARG_PRAZO < 7 )) && LARG_PRAZO=7
}

# Lê uma tecla (trata setas, backspace e enter)
ler_tecla() {
    local tecla resto til
    IFS= read -rsn1 tecla
    if [[ $tecla == $'\x1b' ]]; then
        read -rsn2 -t 0.02 resto
        case "$resto" in
            '[A') echo "CIMA" ;;
            '[B') echo "BAIXO" ;;
            '[C') echo "DIREITA" ;;
            '[D') echo "ESQUERDA" ;;
            '[3') 
                read -rsn1 -t 0.02 til
                [[ "$til" == "~" ]] && echo "DEL" || echo "ESC"
                ;;
            *)    echo "ESC" ;;
        esac
    elif [[ $tecla == $'\x7f' || $tecla == $'\x08' ]]; then
        echo "BACKSPACE"
    elif [[ $tecla == "+" ]]; then
        echo "MAIS"
    elif [[ -z $tecla ]]; then
        echo "ENTER"
    else
        echo "OUTRO"
    fi
}

# Dado um STATUS, define SIMBOLO e COR_STATUS globais
status_info() {
    local status="$1" editor="$2"

    case "$status" in
        ANDAMENTO) SIMBOLO="[>]" ;;
        CONCLUIDA) SIMBOLO="[✓]" ;;
        *)         SIMBOLO="[ ]" ;;
    esac
    case "$editor" in
        pn4711) COR_STATUS="$COR_EMANUEL" ;;
        pn4730) COR_STATUS="$COR_RAYSSA" ;;
        daniele) COR_STATUS="$COR_DANIELE" ;;
        *) COR_STATUS="$COR_CINZA" ;;
    esac

}

proximo_status() {
    case "$1" in
        ABERTA)    echo "ANDAMENTO" ;;
        ANDAMENTO) echo "CONCLUIDA" ;;
        CONCLUIDA) echo "ABERTA" ;;
        *)         echo "ABERTA" ;;
    esac
}

status_anterior() {
    case "$1" in
        ABERTA)    echo "CONCLUIDA" ;;
        ANDAMENTO) echo "ABERTA" ;;
        CONCLUIDA) echo "ANDAMENTO" ;;
        *)         echo "ABERTA" ;;
    esac
}

# --------------------- Desenho da tabela ---------------------

desenhar_tabela() {
    calcular_larguras

    local total=${#IDS[@]}
    local TOPO MEIO BASE
    TOPO="┌──────┬$(repetir $((LARG_TAREFA+2)) ─)┬$(repetir $((LARG_PRIORIDADE+2)) ─)┬$(repetir $((LARG_PRAZO+2)) ─)┐"
    MEIO="├──────┼$(repetir $((LARG_TAREFA+2)) ─)┼$(repetir $((LARG_PRIORIDADE+2)) ─)┼$(repetir $((LARG_PRAZO+2)) ─)┤"
    BASE="└──────┴$(repetir $((LARG_TAREFA+2)) ─)┴$(repetir $((LARG_PRIORIDADE+2)) ─)┴$(repetir $((LARG_PRAZO+2)) ─)┘"
    local largura_interna=$(( ${#TOPO} - 2 ))

    clear
    echo "$TOPO"

    local titulo=" LISTA DE TAREFAS" contagem="[ $((SEL+1))/$total ] "
    local espacos=$(( largura_interna - ${#titulo} - ${#contagem} ))
    printf "│%s%*s%s│\n" "$titulo" "$espacos" "" "$contagem"

    echo "$MEIO"
    # ALTERADO: padding simétrico (espaço dos dois lados) igual às linhas de dados
    printf "│  ST  │ %-*s │ %s │ %s │\n" "$LARG_TAREFA" "TAREFA" \
        "$(centralizar "PRIORIDADE" "$LARG_PRIORIDADE")" \
        "$(centralizar "PRAZO" "$LARG_PRAZO")"
    echo "$MEIO"

    local i ID STATUS PRIOR DESC PRAZO EDITOR PONTEIRO col_st texto_tarefa texto_prior texto_prazo cor_prior
    for (( i=0; i<total; i++ )); do
        ID="${IDS[$i]}"; STATUS="${STATUS_LIST[$i]}"; PRIOR="${PRIORIDADE_LIST[$i]}"
        DESC="${DESCRICOES[$i]}"; PRAZO="${PRAZO_LIST[$i]}"; EDITOR="${EDITOR_LIST[$i]}"

        status_info "$STATUS" "$EDITOR"
        [[ $i -eq $SEL ]] && PONTEIRO="❯" || PONTEIRO=" "
        col_st=$(preencher_direita "$PONTEIRO $SIMBOLO" 6)
        texto_tarefa=$(truncar_esq "$(printf '#%02d %s' "$ID" "$DESC")" "$LARG_TAREFA")
        texto_prior=$(centralizar "$PRIOR" "$LARG_PRIORIDADE")

        if [[ "$STATUS" == "CONCLUIDA" ]]; then
            texto_prazo=$(centralizar "Concl." "$LARG_PRAZO")
        else
            texto_prazo=$(centralizar "${PRAZO:-\-}" "$LARG_PRAZO")
        fi

        case "$PRIOR" in
            ALTA)  cor_prior="$COR_VERMELHO" ;;
            MEDIA) cor_prior="$COR_AMARELO" ;;
            BAIXA) cor_prior="$COR_AZUL" ;;
            *)     cor_prior="$RESET" ;;
        esac

        if (( i == SEL )); then
            echo -e "│${COR_SEL}${col_st}${RESET}│ ${texto_tarefa} │${cor_prior} ${texto_prior} ${RESET}│ ${texto_prazo} │"
        else
            echo -e "│${COR_STATUS}${col_st}${RESET}│ ${texto_tarefa} │${cor_prior} ${texto_prior} ${RESET}│ ${texto_prazo} │"
        fi
    done

    echo "$BASE"
    echo
    echo "↑ ↓ navegar   ← → status   + adicionar   DEL excluir   BACKSPACE voltar"
}

# --------------------- Carregamento dos dados ---------------------

carregar_tarefas() {
    IDS=(); STATUS_LIST=(); PRIORIDADE_LIST=(); DESCRICOES=(); PRAZO_LIST=(); EDITOR_LIST=()
    [[ -s "$ARQ_AFAZERES" ]] || return
    local ID STATUS PRIORIDADE DESC PRAZO EDITOR
    while IFS="|" read -r ID STATUS PRIORIDADE DESC PRAZO EDITOR || [[ -n "$ID" ]]; do
        ID=$(echo "$ID" | tr -d '\r')
        [[ -z "$ID" ]] && continue
        IDS+=("$ID")
        STATUS_LIST+=("$(echo "$STATUS" | tr -d '\r')")
        PRIORIDADE_LIST+=("$(echo "$PRIORIDADE" | tr -d '\r')")
        DESCRICOES+=("$(echo "$DESC" | tr -d '\r')")
        PRAZO_LIST+=("$(echo "$PRAZO" | tr -d '\r')")
        EDITOR_LIST+=("$(echo "$EDITOR" | tr -d '\r')")
    done < "$ARQ_AFAZERES"
}

salvar_status() {
    # salvar_status <id> <novo_status>
    local id="$1" novo="$2" tmp
    tmp=$(mktemp)
    awk -F'|' -v id="$id" -v status="$novo" -v editor="$USUARIO" \
        'BEGIN{OFS="|"} { if ($1==id) { $2=status; $6=editor }; print }' \
        "$ARQ_AFAZERES" > "$tmp"
    mv "$tmp" "$ARQ_AFAZERES"
}

excluir_tarefa() {
    local id="$1" tmp
    tmp=$(mktemp)
    awk -F'|' -v id="$id" '$1 != id' "$ARQ_AFAZERES" > "$tmp"
    mv "$tmp" "$ARQ_AFAZERES"
}

# --------------------- Tela principal (substitui ls_tarefas) ---------------------

ls_tarefas() {
    local IDS STATUS_LIST PRIORIDADE_LIST DESCRICOES PRAZO_LIST EDITOR_LIST SEL=0 tecla total

    while true; do
        carregar_tarefas
        total=${#IDS[@]}

        if (( total == 0 )); then
            clear
            echo "Nenhuma tarefa cadastrada"
            echo
            echo "+ adicionar   BACKSPACE voltar"
            tecla=$(ler_tecla)
            case "$tecla" in
                MAIS) add_tarefa ;;
                BACKSPACE) return ;;
            esac
            continue
        fi

        (( SEL >= total )) && SEL=$(( total - 1 ))
        (( SEL < 0 )) && SEL=0

        desenhar_tabela
        tecla=$(ler_tecla)

        case "$tecla" in
            CIMA)
                SEL=$(( SEL - 1 ))
                (( SEL < 0 )) && SEL=$(( total - 1 ))
                ;;
            BAIXO)
                SEL=$(( SEL + 1 ))
                (( SEL >= total )) && SEL=0
                ;;
            DIREITA)
                salvar_status "${IDS[$SEL]}" "$(proximo_status "${STATUS_LIST[$SEL]}")"
                ;;
            ESQUERDA)
                salvar_status "${IDS[$SEL]}" "$(status_anterior "${STATUS_LIST[$SEL]}")"
                ;;
            MAIS)
                add_tarefa
                ;;
            DEL)
                echo
                read -rp "Excluir a tarefa '${DESCRICOES[$SEL]}'? [s/N]: " CONF
                [[ "$CONF" =~ ^[sS]$ ]] && excluir_tarefa "${IDS[$SEL]}"
                ;;
            BACKSPACE)
                return
                ;;
        esac
    done
}

# --------------------- Adicionar tarefa (agora com PRAZO) ---------------------

add_tarefa() {
    clear
    echo "========================================"
    echo "            ADICIONAR TAREFA"
    echo "========================================"
    echo

    local DESCRICAO ID OPCOES_PRIORIDADE PRIORIDADE PRAZO

    read -e -rp "Breve descrição da tarefa: " DESCRICAO
    if [[ -z "$DESCRICAO" ]]; then
        echo; echo "A descrição não pode estar vazia"
        read -rp "Press ENTER "
        return
    fi

    DESCRICAO=$(normalizar_nfc "$DESCRICAO")
    OPCOES_PRIORIDADE=("Alta" "Média" "Baixa")
    CORES_MENU=("$COR_VERMELHO" "$COR_AMARELO" "$COR_AZUL")
    MENSAGEM_MENU="========================================\n Escolha a prioridade:\n========================================\n"
    selecionar_menu "${OPCOES_PRIORIDADE[@]}"
    case $? in
        0) PRIORIDADE="ALTA" ;;
        1) PRIORIDADE="MEDIA" ;;
        2) PRIORIDADE="BAIXA" ;;
    esac
    echo
    echo "========================================"
    read -e -rp "Prazo (ex: Hoje, Amanhã, 20/09 — ENTER para nenhum): " PRAZO

    if [[ ! -s "$ARQ_AFAZERES" ]]; then
        ID=1
    else
        ID=$(awk -F'|' 'NF >= 1 {print $1}' "$ARQ_AFAZERES" | sort -n | tail -n 1)
        ID=$((ID + 1))
    fi

    echo "$ID|ABERTA|$PRIORIDADE|$DESCRICAO|$PRAZO|" >> "$ARQ_AFAZERES"

    echo; echo "Tarefa adicionada com sucesso!"; echo
    read -rp "Press ENTER  "
}

# --------------------- Menu de tarefas (inalterado) ---------------------

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
        read -rp "Press ENTER "
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
    read -rp "Press ENTER para abrir o nano"
    
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
                echo
                read -rp "Press ENTER"
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
            if [[ ! "$CORRIGIR" =~ ^[nN]$ ]]; then
                CONTINUAR="sim"
            else
                rm -f "$TEMP_DIAG"
                echo
                echo "Diagnóstico descartado"
                echo
                read -rp "Press ENTER"
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

    clear
    echo
    echo "Diagnóstico salvo com sucesso!"
    read -rp "Press ENTER "
    clear
}

abrir_diagnostico(){
    local OPCOES
    local TITULOS_ARR=()
    local BLOCOS=()

    while true; do
        clear
        echo "==================================="
        echo "         LISTAR DIAGNÓSTICOS"
        echo "==================================="

        if [[ ! -s "$ARQ_DIAGNOSTICOS" ]]; then
            echo "Nenhum diagnóstico cadastrado"
            echo
            read -rp "Press ENTER "
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

        HABILITAR_DEL=1
        HABILITAR_ADD=1
        selecionar_menu "${OPCOES[@]}"
        local ESCOLHA=$?

        if [[ $ESCOLHA -eq 255 ]]; then
            return
        fi
        
        if [[ $ESCOLHA -eq 254 ]]; then
            add_diagnostico
            continue
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
        read -rp "Press ENTER para voltar à lista..."
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
    read -rp "Press ENTER "
    clear
}

menu_diagnosticos(){
    while true; do
        clear
        
        local OPCOES=(
            "Abrir diagnóstico"
            "Listar diagnósticos"
        )

        selecionar_menu "${OPCOES[@]}"
        
        local OPCAO=$?

        if [[ $OPCAO -eq 255 ]]; then
            return
        fi

        case $OPCAO in
            0) abrir_diagnostico ;;
            1) ls_diagnostico ;;
        esac
    done
}

# ==========================================
# CHEAT SHEET
# ==========================================

adicionar_comando() {
    local SECAO="$1" ROTULO="$2"
    clear
    echo
    echo "========== ADICIONAR COMANDO - $ROTULO =========="
    echo

    local COMANDO DESCRICAO ID

    read -e -rp "Comando: " COMANDO
    read -e -rp "Descrição: " DESCRICAO

    if [[ -z "$COMANDO" || -z "$DESCRICAO" ]]; then
        echo
        echo "Comando e descrição não podem estar vazios."
        read -rp "Press ENTER "
        return
    fi

    if [[ ! -s "$ARQ_CHEATSHEET" ]]; then
        ID=1
    else
        ID=$(awk -F'|' 'NF >= 1 {print $1}' "$ARQ_CHEATSHEET" | sort -n | tail -n 1)
        ID=$((ID + 1))
    fi

    echo "$ID|$SECAO|$COMANDO|$DESCRICAO" >> "$ARQ_CHEATSHEET"

    echo
    echo "Comando adicionado com sucesso!"
    read -rp "Press ENTER "
}

listar_comandos_secao() {
    local SECAO="$1" ROTULO="$2"
    local OPCOES IDS COMANDOS DESCRICOES ESCOLHA
    local ID SECAO_LINHA COMANDO DESCRICAO
    local ID_SELECIONADO COMANDO_SELECIONADO DESCRICAO_SELECIONADA
    local CONFIRMACAO EXECUTAR TEMP_CS

    while true; do
        clear
        echo "========== $ROTULO =========="
        echo

        OPCOES=()
        IDS=()
        COMANDOS=()
        DESCRICOES=()

        while IFS="|" read -r ID SECAO_LINHA COMANDO DESCRICAO; do
            if [[ -z "$ID" || "$SECAO_LINHA" != "$SECAO" ]]; then continue; fi
            OPCOES+=("$COMANDO")
            IDS+=("$ID")
            COMANDOS+=("$COMANDO")
            DESCRICOES+=("$DESCRICAO")
        done < "$ARQ_CHEATSHEET"

        if [[ ${#OPCOES[@]} -eq 0 ]]; then
            echo "Nenhum comando cadastrado nesta seção"
            echo
        fi

        HABILITAR_DEL=1
        HABILITAR_ADD=1
        selecionar_menu "${OPCOES[@]}"
        ESCOLHA=$?

        if [[ $ESCOLHA -eq 255 ]]; then
            return
        fi

        if [[ $ESCOLHA -eq 254 ]]; then
            adicionar_comando "$SECAO" "$ROTULO"
            continue
        fi

        ID_SELECIONADO="${IDS[$ESCOLHA]}"
        COMANDO_SELECIONADO="${COMANDOS[$ESCOLHA]}"
        DESCRICAO_SELECIONADA="${DESCRICOES[$ESCOLHA]}"

        if [[ "$ACAO_MENU" == "DEL" ]]; then
            echo
            read -rp "Tem certeza que deseja EXCLUIR o comando '${COMANDO_SELECIONADO}'? [s/N]: " CONFIRMACAO
            if [[ "$CONFIRMACAO" =~ ^[sS]$ ]]; then
                TEMP_CS=$(mktemp)
                awk -F '|' -v id="$ID_SELECIONADO" '$1 != id {print $0}' "$ARQ_CHEATSHEET" > "$TEMP_CS"
                mv "$TEMP_CS" "$ARQ_CHEATSHEET"
            fi
            continue
        fi

        clear
        echo "========== DETALHES DO COMANDO =========="
        echo "Comando:    $COMANDO_SELECIONADO"
        echo "Descrição:  $DESCRICAO_SELECIONADA"
        echo "==========================================="
        echo
        read -rp "Deseja executar este comando agora? [s/N]: " EXECUTAR
        if [[ "$EXECUTAR" =~ ^[sS]$ ]]; then
            clear
            bash -c "$COMANDO_SELECIONADO" # roda em subshell isolado, não usa eval no shell atual
            echo
            read -rp "Press ENTER "
        fi
    done
}

menu_cheatsheet() {
    while true; do
        clear
        local OPCOES=(
            "Auditoria/Segurança"
            "Redes"
            "Diagnósticos"
        )

        selecionar_menu "${OPCOES[@]}"
        local OPCAO=$?

        if [[ $OPCAO -eq 255 ]]; then
            return
        fi

        case $OPCAO in
            0) listar_comandos_secao "AUDITORIA" "AUDITORIA/SEGURANÇA" ;;
            1) listar_comandos_secao "REDES" "REDES" ;;
            2) listar_comandos_secao "DIAGNOSTICOS" "DIAGNÓSTICOS" ;;
        esac
    done
}

# ==========================================
# IPs
# ==========================================

validar_ip() {
    local ip="$1"
    local -a OCTETOS
    local OCTETO

    if [[ ! "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 1
    fi

    IFS='.' read -ra OCTETOS <<< "$ip"
    for OCTETO in "${OCTETOS[@]}"; do
        if (( OCTETO > 255 )); then
            return 1
        fi
    done

    return 0
}

adicionar_ip() {
    clear
    echo
    echo "========== ADICIONAR IP =========="
    echo

    local NOME IP DESCRICAO ID

    read -e -rp "Nome da máquina: " NOME
    if [[ -z "$NOME" ]]; then
        echo
        echo "O nome não pode estar vazio"
        read -rp "Press ENTER "
        return
    fi

    read -e -rp "IP: " IP
    if ! validar_ip "$IP"; then
        echo
        echo "IP inválido. Use o formato XXX.XXX.XXX.XXX (cada número entre 0 e 255)"
        read -rp "Press ENTER "
        return
    fi

    read -e -rp "Descrição (opcional): " DESCRICAO

    if [[ ! -s "$ARQ_IPS" ]]; then
        ID=1
    else
        ID=$(awk -F'|' 'NF >= 1 {print $1}' "$ARQ_IPS" | sort -n | tail -n 1)
        ID=$((ID + 1))
    fi

    echo "$ID|$NOME|$IP|$DESCRICAO" >> "$ARQ_IPS"

    echo
    echo "IP adicionado com sucesso!"
    read -rp "Press ENTER "
}

pingar_ip() {
    local IP="$1" NOME="$2"
    clear
    echo "========== PING: $NOME ($IP) =========="
    echo
    echo "Pressione Ctrl+C para interromper"
    echo
    ping -c 4 "$IP"
    echo
    read -rp "Press ENTER "
}

editar_ip() {
    local ID_SELECIONADO="$1" NOME_ATUAL="$2" IP_ATUAL="$3" DESCRICAO_ATUAL="$4"
    local NOVO_NOME NOVO_IP NOVA_DESCRICAO CONFIRMACAO TEMP_IP

    echo
    read -e -i "$NOME_ATUAL" -rp "Nome da máquina: " NOVO_NOME
    read -e -i "$IP_ATUAL" -rp "IP: " NOVO_IP

    if ! validar_ip "$NOVO_IP"; then
        echo
        echo "IP inválido. Edição cancelada"
        read -rp "Press ENTER "
        return
    fi

    read -e -i "$DESCRICAO_ATUAL" -rp "Descrição: " NOVA_DESCRICAO

    echo
    read -rp "Confirma salvar essa alteração? [s/N]: " CONFIRMACAO
    if [[ ! "$CONFIRMACAO" =~ ^[sS]$ ]]; then
        echo
        echo "Alteração cancelada"
        read -rp "Press ENTER "
        return
    fi

    TEMP_IP=$(mktemp)
    awk -F'|' -v id="$ID_SELECIONADO" -v nome="$NOVO_NOME" -v ip="$NOVO_IP" -v desc="$NOVA_DESCRICAO" \
        'BEGIN{OFS="|"} { if ($1 == id) { $2=nome; $3=ip; $4=desc }; print }' "$ARQ_IPS" > "$TEMP_IP"
    mv "$TEMP_IP" "$ARQ_IPS"

    echo
    echo "IP atualizado com sucesso!"
    read -rp "Press ENTER "
}

listar_ips() {
    local OPCOES IDS NOMES IPS DESCRICOES ESCOLHA
    local ID NOME IP DESCRICAO
    local ID_SELECIONADO NOME_SELECIONADO IP_SELECIONADO DESCRICAO_SELECIONADA
    local CONFIRMACAO OPCOES_ACAO ESCOLHA_ACAO TEMP_IP

    while true; do
        clear
        echo "========== LISTA DE IPs =========="
        echo

        if [[ ! -s "$ARQ_IPS" ]]; then
            echo "Nenhum IP cadastrado"
            echo
            read -rp "Press ENTER "
            return
        fi

        OPCOES=()
        IDS=()
        NOMES=()
        IPS=()
        DESCRICOES=()

        while IFS="|" read -r ID NOME IP DESCRICAO; do
            if [[ -z "$ID" ]]; then continue; fi
            OPCOES+=("$NOME ($IP)")
            IDS+=("$ID")
            NOMES+=("$NOME")
            IPS+=("$IP")
            DESCRICOES+=("$DESCRICAO")
        done < <(sort -n "$ARQ_IPS")

        HABILITAR_DEL=1
        selecionar_menu "${OPCOES[@]}"
        ESCOLHA=$?

        if [[ $ESCOLHA -eq 255 ]]; then
            return
        fi

        ID_SELECIONADO="${IDS[$ESCOLHA]}"
        NOME_SELECIONADO="${NOMES[$ESCOLHA]}"
        IP_SELECIONADO="${IPS[$ESCOLHA]}"
        DESCRICAO_SELECIONADA="${DESCRICOES[$ESCOLHA]}"

        if [[ "$ACAO_MENU" == "DEL" ]]; then
            echo
            read -rp "Tem certeza que deseja EXCLUIR '${NOME_SELECIONADO}'? [s/N]: " CONFIRMACAO
            if [[ "$CONFIRMACAO" =~ ^[sS]$ ]]; then
                TEMP_IP=$(mktemp)
                awk -F '|' -v id="$ID_SELECIONADO" '$1 != id {print $0}' "$ARQ_IPS" > "$TEMP_IP"
                mv "$TEMP_IP" "$ARQ_IPS"
            fi
            continue
        fi

        clear
        echo "========== DETALHES =========="
        echo "Nome:       $NOME_SELECIONADO"
        echo "IP:         $IP_SELECIONADO"
        echo "Descrição:  $DESCRICAO_SELECIONADA"
        echo "================================"
        echo

        OPCOES_ACAO=("Pingar" "Editar" "Voltar")
        selecionar_menu "${OPCOES_ACAO[@]}"
        ESCOLHA_ACAO=$?

        case $ESCOLHA_ACAO in
            0) pingar_ip "$IP_SELECIONADO" "$NOME_SELECIONADO" ;;
            1) editar_ip "$ID_SELECIONADO" "$NOME_SELECIONADO" "$IP_SELECIONADO" "$DESCRICAO_SELECIONADA" ;;
            *) continue ;;
        esac
    done
}

listar_conexoes_samba() {
    clear
    echo "========== IPs CONECTADOS AO SAMBA =========="
    echo

    if ! command -v smbstatus >/dev/null 2>&1; then
        echo "[ ERRO ] Comando 'smbstatus' não encontrado"
        echo
        read -rp "Press ENTER "
        return
    fi

    local SAIDA_SMBSTATUS PIDS PID USUARIO IP DATA_CONEXAO LINHA_CONEXAO LINHA_SERVICO

    SAIDA_SMBSTATUS=$(sudo smbstatus 2>/dev/null)

    # tabela de conexões: linhas que começam com um PID numérico
    PIDS=$(echo "$SAIDA_SMBSTATUS" | awk '/^[0-9]+[[:space:]]/ {print $1}' | sort -u)

    if [[ -z "$PIDS" ]]; then
        echo "Nenhuma conexão ativa no Samba no momento"
        echo
        read -rp "Press ENTER "
        return
    fi

    printf "%-15s %-16s %-24s" "USUÁRIO" "        IP" " CONECTADO EM"
    echo "-------------------------------------------------"

    while IFS= read -r PID; do
        LINHA_CONEXAO=$(echo "$SAIDA_SMBSTATUS" | awk -v pid="$PID" '$1 == pid {print; exit}')
        USUARIO=$(echo "$LINHA_CONEXAO" | awk '{print $2}')
        IP=$(echo "$LINHA_CONEXAO" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -n 1)

        # tabela de serviços: PID é o 2º campo aqui, e traz o "Connected at"
        LINHA_SERVICO=$(echo "$SAIDA_SMBSTATUS" | awk -v pid="$PID" '$2 == pid {print; exit}')
        DATA_CONEXAO=$(echo "$LINHA_SERVICO" | grep -oE '[A-Za-z]{3} [A-Za-z]{3}[[:space:]]+[0-9]{1,2} [0-9]{2}:[0-9]{2}:[0-9]{2} [0-9]{4}')
        [[ -z "$DATA_CONEXAO" ]] && DATA_CONEXAO="?"

        printf "%-15s %-16s %-24s" "${USUARIO:-?}" "${IP:-?}" "$DATA_CONEXAO\n"
    done <<< "$PIDS"

    echo
    read -rp "Press ENTER "
}

buscar_ip_octeto() {
    clear
    echo "========== BUSCAR POR OCTETO FINAL =========="
    echo

    local OCTETO

    read -e -rp "Digite o octeto final (0-255): " OCTETO

    if [[ ! "$OCTETO" =~ ^[0-9]{1,3}$ ]] || (( OCTETO > 255 )); then
        echo
        echo "Octeto inválido"
        read -rp "Press ENTER "
        return
    fi

    if [[ ! -s "$ARQ_IPS" ]]; then
        echo
        echo "Nenhum IP cadastrado"
        read -rp "Press ENTER "
        return
    fi

    local OPCOES IDS NOMES IPS DESCRICOES ID NOME IP DESCRICAO ESCOLHA ESCOLHA_ACAO OPCOES_ACAO

    OPCOES=(); IDS=(); NOMES=(); IPS=(); DESCRICOES=()

    while IFS="|" read -r ID NOME IP DESCRICAO; do
        if [[ -z "$ID" ]]; then continue; fi
        if [[ "${IP##*.}" == "$OCTETO" ]]; then
            OPCOES+=("$NOME ($IP)")
            IDS+=("$ID")
            NOMES+=("$NOME")
            IPS+=("$IP")
            DESCRICOES+=("$DESCRICAO")
        fi
    done < <(sort -n "$ARQ_IPS")

    if [[ ${#OPCOES[@]} -eq 0 ]]; then
        echo
        echo "Nenhum IP cadastrado terminando em .$OCTETO"
        read -rp "Press ENTER "
        return
    fi

    while true; do
        selecionar_menu "${OPCOES[@]}"
        ESCOLHA=$?

        if [[ $ESCOLHA -eq 255 ]]; then
            return
        fi

        clear
        echo "========== DETALHES =========="
        echo "Nome:       ${NOMES[$ESCOLHA]}"
        echo "IP:         ${IPS[$ESCOLHA]}"
        echo "Descrição:  ${DESCRICOES[$ESCOLHA]}"
        echo "================================"
        echo

        OPCOES_ACAO=("Pingar" "Voltar")
        selecionar_menu "${OPCOES_ACAO[@]}"
        ESCOLHA_ACAO=$?

        if [[ $ESCOLHA_ACAO -eq 0 ]]; then
            pingar_ip "${IPS[$ESCOLHA]}" "${NOMES[$ESCOLHA]}"
        fi
    done
}

escanear_vizinhos() {
    local LINHA IP MAC TEMP_VIZ

    while IFS= read -r LINHA; do
        IP=$(awk '{print $1}' <<< "$LINHA")
        MAC=$(grep -oE '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}' <<< "$LINHA")

        if [[ -z "$IP" || -z "$MAC" ]]; then continue; fi

        TEMP_VIZ=$(mktemp)
        awk -F'|' -v mac="$MAC" -v ip="$IP" '
            BEGIN { OFS="|"; achou=0 }
            {
                if (tolower($1) == tolower(mac)) { $3=ip; achou=1 }
                print
            }
            END {
                if (!achou) print mac "||" ip
            }
        ' "$ARQ_VIZINHOS" > "$TEMP_VIZ"
        mv "$TEMP_VIZ" "$ARQ_VIZINHOS"
    done < <(ip -4 neigh show 2>/dev/null | grep -E 'lladdr')
}

listar_vizinhos() {
    local OPCOES MACS NOMES IPS ESCOLHA
    local MAC NOME IP
    local MAC_SEL NOME_SEL IP_SEL NOVO_NOME CONFIRMACAO TEMP_VIZ

    while true; do
        clear
        echo "========== VIZINHOS DA REDE =========="
        echo
        echo "Escaneando..."
        escanear_vizinhos

        OPCOES=(); MACS=(); NOMES=(); IPS=()

        while IFS="|" read -r MAC NOME IP; do
            if [[ -z "$MAC" ]]; then continue; fi
            if [[ -n "$NOME" ]]; then
                OPCOES+=("$NOME ($IP)")
            else
                OPCOES+=("(sem nome) ($IP) — $MAC")
            fi
            MACS+=("$MAC")
            NOMES+=("$NOME")
            IPS+=("$IP")
        done < "$ARQ_VIZINHOS"

        if [[ ${#OPCOES[@]} -eq 0 ]]; then
            clear
            echo "Nenhum vizinho encontrado na rede"
            echo
            read -rp "Press ENTER "
            return
        fi

        HABILITAR_DEL=1
        selecionar_menu "${OPCOES[@]}"
        ESCOLHA=$?

        if [[ $ESCOLHA -eq 255 ]]; then
            return
        fi

        MAC_SEL="${MACS[$ESCOLHA]}"
        NOME_SEL="${NOMES[$ESCOLHA]}"
        IP_SEL="${IPS[$ESCOLHA]}"

        if [[ "$ACAO_MENU" == "DEL" ]]; then
            echo
            read -rp "Tem certeza que deseja EXCLUIR este vizinho do catálogo? [s/N]: " CONFIRMACAO
            if [[ "$CONFIRMACAO" =~ ^[sS]$ ]]; then
                TEMP_VIZ=$(mktemp)
                awk -F'|' -v mac="$MAC_SEL" 'tolower($1) != tolower(mac)' "$ARQ_VIZINHOS" > "$TEMP_VIZ"
                mv "$TEMP_VIZ" "$ARQ_VIZINHOS"
            fi
            continue
        fi

        clear
        echo "========== DETALHES DO VIZINHO =========="
        echo "Nome:  ${NOME_SEL:-(sem nome)}"
        echo "IP:    $IP_SEL"
        echo "MAC:   $MAC_SEL"
        echo "==========================================="
        echo
        read -e -i "$NOME_SEL" -rp "Nome (ENTER mantém, apagar tudo remove o nome): " NOVO_NOME

        TEMP_VIZ=$(mktemp)
        awk -F'|' -v mac="$MAC_SEL" -v nome="$NOVO_NOME" 'BEGIN{OFS="|"} { if (tolower($1)==tolower(mac)) $2=nome; print }' "$ARQ_VIZINHOS" > "$TEMP_VIZ"
        mv "$TEMP_VIZ" "$ARQ_VIZINHOS"
    done
}

menu_ips() {
    while true; do
        clear
        local OPCOES=(
            "Adicionar IP"
            "Listar IPs"
            "IPs conectados ao Samba"
            "Buscar por octeto final"
            "Vizinhos da rede" 
        )

        selecionar_menu "${OPCOES[@]}"
        local OPCAO=$?

        if [[ $OPCAO -eq 255 ]]; then
            return
        fi

        case $OPCAO in
            0) adicionar_ip ;;
            1) listar_ips ;;
            2) listar_conexoes_samba ;;
            3) buscar_ip_octeto ;;
            4) listar_vizinhos ;;
        esac
    done
}

# ==========================================
# INSTRUÇÕES
# ==========================================

adicionar_passo() {
    clear
    echo
    echo "========== NOVO PASSO A PASSO =========="
    echo

    local TITULO DESCRICAO_BREVE NOME DATA_PASSO ARQUIVO_PASSO TEMP_PASSO CONTEUDO

    read -e -rp "Título: " TITULO
    if [[ -z "$TITULO" ]]; then
        echo
        echo "O título não pode estar vazio"
        read -rp "Press ENTER "
        return
    fi

    read -e -rp "Breve descrição: " DESCRICAO_BREVE

    TEMP_PASSO=$(mktemp)
    clear
    read -rp "Press ENTER para abrir o nano e escrever o passo a passo"

    nano "$TEMP_PASSO"
    CONTEUDO=$(cat "$TEMP_PASSO")
    rm -f "$TEMP_PASSO"

    if [[ -z "$CONTEUDO" ]]; then
        echo
        echo "O conteúdo não pode estar vazio"
        read -rp "Press ENTER "
        return
    fi

    NOME=$(echo "$TITULO" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
    DATA_PASSO=$(date '+%d-%m-%Y')
    ARQUIVO_PASSO="$DIR_INSTRUCOES/${DATA_PASSO}-${NOME}.txt"

    {
        echo "========================================="
        echo "            PASSO A PASSO"
        echo "========================================="
        echo
        echo "TÍTULO: $TITULO"
        echo "DESCRIÇÃO: $DESCRICAO_BREVE"
        echo "DATA: $DATA_PASSO"
        echo
        echo "========================================="
        echo
        printf "%s" "$CONTEUDO"
        echo
    } > "$ARQUIVO_PASSO"

    echo
    echo "Passo a passo salvo com sucesso!"
    read -rp "Press ENTER "
}

listar_passos() {
    local OPCOES ARQUIVOS_ENCONTRADOS ARQUIVO_ATUAL TITULO DESCRICAO
    local ESCOLHA CONFIRMACAO TITULO_SELECIONADO

    while true; do
        clear
        echo "========== PASSO A PASSO =========="
        echo

        OPCOES=(); ARQUIVOS_ENCONTRADOS=()

        while IFS= read -r ARQUIVO_ATUAL; do
            if [[ -z "$ARQUIVO_ATUAL" ]]; then continue; fi
            TITULO=$(grep "^TÍTULO:" "$ARQUIVO_ATUAL" | sed 's/^TÍTULO: //')
            DESCRICAO=$(grep "^DESCRIÇÃO:" "$ARQUIVO_ATUAL" | sed 's/^DESCRIÇÃO: //')
            OPCOES+=("$TITULO")
            ARQUIVOS_ENCONTRADOS+=("$ARQUIVO_ATUAL")
        done < <(find "$DIR_INSTRUCOES" -maxdepth 1 -type f -name "*.txt" | sort)

        if [[ ${#OPCOES[@]} -eq 0 ]]; then
            echo "Nenhum passo a passo cadastrado ainda"
            echo
        fi

        HABILITAR_DEL=1
        HABILITAR_ADD=1
        selecionar_menu "${OPCOES[@]}"
        ESCOLHA=$?

        if [[ $ESCOLHA -eq 255 ]]; then
            return
        fi

        if [[ $ESCOLHA -eq 254 ]]; then
            adicionar_passo
            continue
        fi

        if [[ ${#OPCOES[@]} -eq 0 ]]; then
            continue
        fi

        TITULO_SELECIONADO="${OPCOES[$ESCOLHA]}"

        if [[ "$ACAO_MENU" == "DEL" ]]; then
            echo
            read -rp "Tem certeza que deseja EXCLUIR '${TITULO_SELECIONADO}'? [s/N]: " CONFIRMACAO
            if [[ "$CONFIRMACAO" =~ ^[sS]$ ]]; then
                rm -f "${ARQUIVOS_ENCONTRADOS[$ESCOLHA]}"
            fi
            continue
        fi

        clear
        cat "${ARQUIVOS_ENCONTRADOS[$ESCOLHA]}"
        echo
        echo "========================================="
        read -rp "Press ENTER para voltar à lista..."
    done
}

# ==========================================
# LOGS
# ==========================================

perguntar_linhas() {
    local LINHAS
    read -e -rp "Quantas linhas deseja ver? " LINHAS >&2

    if [[ ! "$LINHAS" =~ ^[0-9]+$ ]]; then
        echo "[ INFO ] Entrada inválida. Exibindo 25 linhas por padrão"
        LINHAS=25
    fi

    echo "$LINHAS"
}

exibir_log_arquivo() {
    local CAMINHO=$1 LINHAS

    if [[ ! -f "$CAMINHO" ]]; then
        echo
        echo "[ ERRO ] Log não encontrado em: $CAMINHO"
        echo
        echo "Confirme se o caminho está correto"
        echo
        read -rp "Press ENTER"
        return
    fi

    echo
    read -rp "Deseja acompanhar em tempo real? [s/N]: " OPCAO
    if [[ "$OPCAO" =~ ^[sS]$ ]]; then
        clear
        echo "Pressione Ctrl+C para sair do acompanhamento em tempo real"
        read -rp "Press ENTER para continuar..."
        tail -fn 30 "$CAMINHO"
    else
        LINHAS=$(perguntar_linhas)
        clear
        tail -n "$LINHAS" "$CAMINHO"
        echo
        read -rp "Press ENTER"
    fi
}

exibir_log_journalctl() {
    local UNIT=$1 LINHAS

    echo
    read -rp "Deseja acompanhar em tempo real? [s/N]: " OPCAO
    if [[ "$OPCAO" =~ ^[sS]$ ]]; then
        clear
        echo "Pressione Ctrl+C para sair do acompanhamento em tempo real"
        read -rp "Press ENTER para continuar..."
        sudo journalctl -u "$UNIT" -fn 30
    else
        LINHAS=$(perguntar_linhas)
        clear
        sudo journalctl -u "$UNIT" -n "$LINHAS"
        echo
        read -rp "Press ENTER"
    fi
}

menu_script() {
    local NOME_EXIBICAO="$1" CAMINHO_LOG="$2" CAMINHO_SCRIPT="$3" OPCOES
    while true; do
        clear
        echo "========== $NOME_EXIBICAO =========="
        echo

        OPCOES=(
            "Ver último log"
            "Executar agora"
        )

        selecionar_menu "${OPCOES[@]}"
        local ESCOLHA=$?
        
        if [[ $ESCOLHA -eq 255 ]]; then
            return
        fi

        case $ESCOLHA in
            0) exibir_log_arquivo "$CAMINHO_LOG" ;;
            1)
                clear
                (sudo "$CAMINHO_SCRIPT")
                echo
                read -rp "Press ENTER" ;;
        esac
    done
}

menu_scripts() {
    local OPCOES
    while true; do
        clear
        echo "========== SCRIPTS =========="
        echo

        OPCOES=(
            "Limpeza"
            "Storage"
            "Monitoramento"
        )

        selecionar_menu "${OPCOES[@]}"
        
        local ESCOLHA="$?"

        if [[ $ESCOLHA -eq 255 ]]; then
            return
        fi 

        case $ESCOLHA in
            0) menu_script "LIMPEZA" "/var/log/limpeza/limpeza-atual.log" "/scripts/auto-remove.sh" ;;
            1) menu_script "STORAGE" "/var/log/backupsamba/consumo_atual.log" "/scripts/storage.sh" ;;
            2) menu_script "MONITORAMENTO" "/var/log/minipc-monitoring/ultimo_monitoramento.log" "/scripts/monitoramento.sh" ;;
        esac
    done
}

menu_gotify() {
    local OPCOES
    while true; do
        clear
        echo "========== GOTIFY =========="
        echo

        OPCOES=(
            "Journalctl"
        )

        selecionar_menu "${OPCOES[@]}"

        local ESCOLHA=$?

        if [[ $ESCOLHA -eq 255 ]]; then
            return
        fi

        case $ESCOLHA in
            0) exibir_log_journalctl "gotify" ;;
        esac
    done
}

ls_logs_samba() {
    local OPCOES ARQUIVOS_ENCONTRADOS NOME_ARQUIVO ESCOLHA
    while true; do
        clear
        echo "========== ARQUIVOS DE LOG - SAMBA =========="
        echo

        if ! ls /var/log/samba/*.log >/dev/null 2>&1 && ! ls /var/log/samba/log.* >/dev/null 2>&1; then
            echo "Nenhum arquivo de log encontrado em /var/log/samba/"
            echo
            read -rp "Press ENTER "
            return
        fi

        OPCOES=()
        ARQUIVOS_ENCONTRADOS=()

        while IFS= read -r NOME_ARQUIVO; do
            if [[ -z "$NOME_ARQUIVO" ]]; then continue; fi
            OPCOES+=("$(basename "$NOME_ARQUIVO")")
            ARQUIVOS_ENCONTRADOS+=("$NOME_ARQUIVO")
        done < <(find /var/log/samba -maxdepth 1 -type f | sort)

        selecionar_menu "${OPCOES[@]}"

        ESCOLHA=$?

        if [[ $ESCOLHA -eq 255 ]]; then
            return
        fi

        exibir_log_arquivo "${ARQUIVOS_ENCONTRADOS[$ESCOLHA]}"
    done
}

menu_samba() {
    local OPCOES
    while true; do
        clear
        echo "========== SAMBA =========="
        echo

        OPCOES=(
            "Journalctl"
            "Arquivo de log"
        )

        selecionar_menu "${OPCOES[@]}"
        
        local ESCOLHA=$?

        if [[ $ESCOLHA -eq 255 ]]; then
            return
        fi

        case "$ESCOLHA" in
            0) exibir_log_journalctl "smbd" ;;
            1) ls_logs_samba ;;
        esac
    done
}

status_fail2ban() {
    clear
    echo "========== STATUS - FAIL2BAN =========="
    echo

    if ! command -v fail2ban-client >/dev/null 2>&1; then
        echo "[ ERRO ] Comando 'fail2ban-client' não encontrado"
        return
    fi

    echo "--- Jails ativas ---"
    sudo fail2ban-client status
    echo

    local JAIL JAILS
    JAILS=$(sudo fail2ban-client status | grep "Jail list" | sed 's/.*://;s/,//g')

    for JAIL in $JAILS; do
        echo "--- $JAIL ---"
        sudo fail2ban-client status "$JAIL"
        echo
    done

    read -rp "Press ENTER"
}

menu_fail2ban() {
    local OPCOES

    while true; do
        clear
        echo "========== FAIL2BAN =========="
        echo

        OPCOES=(
            "Journalctl"
            "Arquivo de log"
            "Status (jails e IPs banidos)"
        )

        selecionar_menu "${OPCOES[@]}"

        local ESCOLHA="$?"

        if [[ $ESCOLHA -eq 255 ]]; then
            return
        fi

        case "$ESCOLHA" in
            0) exibir_log_journalctl "fail2ban" ;;
            1) exibir_log_arquivo "/var/log/fail2ban.log" ;;
            2) status_fail2ban ;;
        esac
    done
}

menu_logs(){
    while true; do
        clear

        local OPCOES
        OPCOES=(
            "Scripts"
            "Samba"
            "Fail2ban"
            "Gotify"
        )
        
        selecionar_menu "${OPCOES[@]}"
        
        local ESCOLHA="$?"

        if [[ $ESCOLHA -eq 255 ]]; then
            return
        fi

        case $ESCOLHA in
            0) menu_scripts ;;
            1) menu_samba ;;
            2) menu_fail2ban ;;
            3) exibir_log_journalctl "gotify" ;;
            #3) menu_gotify ;;
        esac
    done
}

# ==========================================
# FEEDBACK
# ==========================================

cabecalho_feedback() {
    local ARQ_FEEDBACK_USUARIO="$1"
    local NOME_EXIBICAO DATA_ATUAL
    DATA_ATUAL=$(date '+%d-%m-%Y')

    if [[ -f "$ARQ_FEEDBACK_USUARIO" ]] && grep -q "^DATA: $DATA_ATUAL$" "$ARQ_FEEDBACK_USUARIO"; then
        return
    fi

    NOME_EXIBICAO=$(awk -F'=' -v usuario="$USUARIO" '$1 == usuario {print $2; exit}' "$ARQ_USUARIOS")
    if [[ -z "$NOME_EXIBICAO" ]]; then
        NOME_EXIBICAO="$USUARIO"
    fi
    
    {
        echo "DATA: $DATA_ATUAL"
        echo "USUARIO: $USUARIO"
        echo
        echo "Boa noite, pessoal! Segue o feedback do dia de hoje: ($DATA) - $NOME_EXIBICAO"
        echo
    } > "$ARQ_FEEDBACK_USUARIO"
}

gerar_feedback() {

    echo
    echo "========== FEEDBACK =========="
    echo

    if [[ ! -f "$ARQUIVO" ]]; then
        echo "Não existe registro para hoje."
        return
    fi
    
    local USUARIO_LOWER ARQ_FEEDBACK_USUARIO ADICIONAR LINHA

    USUARIO_LOWER=$(echo "$USUARIO" | tr '[:upper:]' '[:lower:]' )
    ARQ_FEEDBACK_USUARIO="$DIR_FEEDBACK/feedback-${USUARIO_LOWER}.txt"
    
    cabecalho_feedback "$ARQ_FEEDBACK_USUARIO"

    while true; do
        clear
        echo "========== FEEDBACK =========="
        echo
        cat "$ARQ_FEEDBACK_USUARIO"
        echo
        echo "Bom descanso a todos! 🧬" # ALTERADO: rodapé só é exibido aqui, não fica mais gravado no arquivo
        echo

        read -rp "Deseja adicionar algo ao feedback? [s/N]: " ADICIONAR

        if [[ "$ADICIONAR" =~ ^[sS]$ ]]; then
            clear
            echo
            echo "Digite o que deseja adicionar"
            echo "Digite FIM em uma linha separada quando terminar"
            echo

            while true; do
                read -e -r LINHA
                if [[ "$LINHA" == "FIM" ]]; then
                    break
                fi
                if [[ -n "${LINHA//[$'\n\r ']/}" ]]; then
                    echo "- $LINHA" >> "$ARQ_FEEDBACK_USUARIO"
                fi
            done
            continue
        fi
        break
    done

    clear
    echo "========== FEEDBACK =========="
    echo
    cat "$ARQ_FEEDBACK_USUARIO"
    echo
    echo "Bom descanso a todos! 🧬"
    echo
    read -rp "Press ENTER para voltar ao menu..."
}

editar_feedback() {

    local USUARIO_LOWER ARQ_FEEDBACK_USUARIO
    USUARIO_LOWER=$(echo "$USUARIO" | tr '[:upper:]' '[:lower:]' )
    ARQ_FEEDBACK_USUARIO="$DIR_FEEDBACK/feedback-${USUARIO_LOWER}.txt"

    if [[ ! -f "$ARQ_FEEDBACK_USUARIO" ]]; then
        echo
        echo "Ainda não existe um feedback para editar."
        read -rp "Press ENTER "
        return
    fi

    nano "$ARQ_FEEDBACK_USUARIO"
}

url_encode() {
    local LC_ALL=C # força iteração byte a byte (não caractere), essencial para UTF-8 multibyte (acentos, ç, emojis...)
    local STRING="$1"
    local TAMANHO=${#STRING}
    local CARACTERE CARACTERE_HEX i CODIFICADO=""

    for (( i =0; i < TAMANHO; i++ )); do
        CARACTERE="${STRING:i:1}"
        case "$CARACTERE" in
            [a-zA-Z0-9.~_-]) CODIFICADO+="$CARACTERE" ;;
            *)
                printf -v CARACTERE_HEX '%%%02X' "'$CARACTERE"
                CODIFICADO+="$CARACTERE_HEX"
                ;;
        esac
    done
    printf '%s' "$CODIFICADO"
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

        selecionar_menu "${OPCOES[@]}"
        
        ESCOLHA="$?"

        if [[ $ESCOLHA -eq 255 ]]; then
            return
        fi

        CONTEUDO_FEEDBACK=$(grep -vE '^(DATA|USUARIO): ' "${ARQUIVOS_ENCONTRADOS[$ESCOLHA]}" | sed '/./,$!d')
        CONTEUDO_FEEDBACK+=$'\n\nBom descanso a todos! 🧬'

        clear
        echo "========== PRÉVIA (como aparece aqui no terminal) =========="
        echo
        echo "$CONTEUDO_FEEDBACK"
        echo
        echo "=============================================================="
        echo "OBS: o WhatsApp pode não exibir o emoji corretamente — limitação do lado de lá, já confirmada"
        echo
        read -rp "Press ENTER para gerar o link e abrir no WhatsApp..."

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

        read -rp "Press ENTER"
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
        )

        selecionar_menu "${OPCOES[@]}"
        
        local ESCOLHA=$?

        if [[ $ESCOLHA -eq 255 ]]; then
            return
        fi

        case "$ESCOLHA" in
            0) gerar_feedback ;;
            1) editar_feedback ;;
            2) enviar_feedback_wpp ;;
        esac
    done
}

# ==========================================
# DASHBOARD
# ==========================================

obter_uso_cpu() {
    local _ u1 n1 s1 i1 w1 irq1 sirq1
    local u2 n2 s2 i2 w2 irq2 sirq2
    local total1 total2 idle1 idle2 diff_total diff_idle uso

    read -r _ u1 n1 s1 i1 w1 irq1 sirq1 _ < /proc/stat
    total1=$((u1+n1+s1+i1+w1+irq1+sirq1))
    idle1=$i1

    sleep 0.5

    read -r _ u2 n2 s2 i2 w2 irq2 sirq2 _ < /proc/stat
    total2=$((u2+n2+s2+i2+w2+irq2+sirq2))
    idle2=$i2

    diff_total=$((total2-total1))
    diff_idle=$((idle2-idle1))

    if (( diff_total > 0 )); then
        uso=$(awk -v t="$diff_total" -v i="$diff_idle" 'BEGIN{printf "%.2f", (t-i)*100/t}')
    else
        uso="0.00"
    fi

    echo "$uso"
}

obter_temp_cpu() {
    local zona arq_tipo tipo temp_bruta=""

    for zona in /sys/class/thermal/thermal_zone*; do
        [[ -d "$zona" ]] || continue
        arq_tipo="$zona/type"
        if [[ -f "$arq_tipo" ]]; then
            tipo=$(cat "$arq_tipo" 2>/dev/null)
            if [[ "$tipo" =~ ^(x86_pkg_temp|cpu-thermal|coretemp|acpitz)$ ]] && [[ -f "$zona/temp" ]]; then
                temp_bruta=$(cat "$zona/temp" 2>/dev/null)
                break
            fi
        fi
    done

    if [[ -z "$temp_bruta" && -f /sys/class/thermal/thermal_zone0/temp ]]; then
        temp_bruta=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
    fi

    if [[ -n "$temp_bruta" && "$temp_bruta" =~ ^[0-9]+$ ]]; then
        awk -v t="$temp_bruta" 'BEGIN{printf "%.1f", t/1000}'
    else
        echo "N/D"
    fi
}

obter_load_average() {
    awk '{print $1", "$2", "$3}' /proc/loadavg 2>/dev/null
}

obter_memoria() {
    local total_kb free_kb buffers_kb cached_kb sreclaim_kb swap_total_kb swap_free_kb

    total_kb=$(awk '/^MemTotal:/{print $2}' /proc/meminfo)
    free_kb=$(awk '/^MemFree:/{print $2}' /proc/meminfo)
    buffers_kb=$(awk '/^Buffers:/{print $2}' /proc/meminfo)
    cached_kb=$(awk '/^Cached:/{print $2; exit}' /proc/meminfo)
    sreclaim_kb=$(awk '/^SReclaimable:/{print $2}' /proc/meminfo)
    swap_total_kb=$(awk '/^SwapTotal:/{print $2}' /proc/meminfo)
    swap_free_kb=$(awk '/^SwapFree:/{print $2}' /proc/meminfo)

    awk -v total="${total_kb:-0}" -v free="${free_kb:-0}" -v buffers="${buffers_kb:-0}" \
        -v cached="${cached_kb:-0}" -v sreclaim="${sreclaim_kb:-0}" \
        -v swap_total="${swap_total_kb:-0}" -v swap_free="${swap_free_kb:-0}" '
    BEGIN {
        cache = buffers + cached + sreclaim
        usada = total - free - buffers - cached - sreclaim
        if (usada < 0) usada = 0
        uso_pct = (total > 0) ? (usada*100/total) : 0
        swap_usada = swap_total - swap_free
        swap_pct = (swap_total > 0) ? (swap_usada*100/swap_total) : 0
        printf "%.2f|%d|%d|%d|%d|%.2f", uso_pct, total/1024, usada/1024, free/1024, cache/1024, swap_pct
    }'
}

obter_disco_root() {
    local uso_pct inodes_pct
    uso_pct=$(df -h / 2>/dev/null | awk 'NR==2 {gsub("%","",$5); print $5}')
    inodes_pct=$(df -i / 2>/dev/null | awk 'NR==2 {gsub("%","",$5); print $5}')
    echo "${uso_pct:-0}|${inodes_pct:-0}"
}

obter_rede() {
    local iface rx_bytes tx_bytes rx_mb tx_mb
    iface=$(ip route 2>/dev/null | awk '/^default/ {print $5; exit}')
    if [[ -z "$iface" ]]; then
        echo "N/D|0.00|0.00"
        return
    fi
    rx_bytes=$(cat "/sys/class/net/$iface/statistics/rx_bytes" 2>/dev/null)
    tx_bytes=$(cat "/sys/class/net/$iface/statistics/tx_bytes" 2>/dev/null)
    rx_mb=$(awk -v b="${rx_bytes:-0}" 'BEGIN{printf "%.2f", b/1024/1024}')
    tx_mb=$(awk -v b="${tx_bytes:-0}" 'BEGIN{printf "%.2f", b/1024/1024}')
    echo "${iface}|${rx_mb}|${tx_mb}"
}

dashboard() {
    clear
    echo "Calculando métricas (leva cerca de meio segundo)..."

    local uso_cpu temp_cpu load_avg
    local mem_info uso_ram_pct ram_total ram_usada ram_livre ram_cache swap_pct
    local disco_info uso_disco inodes_disco
    local tempo_ligado
    local rede_info iface rx_mb tx_mb

    uso_cpu=$(obter_uso_cpu)
    temp_cpu=$(obter_temp_cpu)
    load_avg=$(obter_load_average)

    mem_info=$(obter_memoria)
    IFS='|' read -r uso_ram_pct ram_total ram_usada ram_livre ram_cache swap_pct <<< "$mem_info"

    disco_info=$(obter_disco_root)
    IFS='|' read -r uso_disco inodes_disco <<< "$disco_info"

    tempo_ligado=$(uptime -p 2>/dev/null)

    rede_info=$(obter_rede)
    IFS='|' read -r iface rx_mb tx_mb <<< "$rede_info"

    clear
    echo "[ PROCESSADOR ]"
    printf "%-22s: %s%%\n" "Uso de CPU" "$uso_cpu"
    printf "%-22s: %s °C\n" "Temperatura CPU" "$temp_cpu"
    printf "%-22s: %s\n" "Load Average" "$load_avg"
    echo
    echo "[ MEMÓRIA RAM ]"
    printf "%-22s: %s%%\n" "Uso de RAM (%)" "$uso_ram_pct"
    printf "%-22s: %s MB\n" "RAM Total" "$ram_total"
    printf "%-22s: %s MB\n" "RAM Usada" "$ram_usada"
    printf "%-22s: %s MB\n" "RAM Livre" "$ram_livre"
    printf "%-22s: %s MB\n" "RAM em Cache/Buffer" "$ram_cache"
    printf "%-22s: %s%%\n" "Uso de Swap (%)" "$swap_pct"
    echo
    echo "[ SISTEMA E DISCO ]"
    printf "%-22s: %s%%\n" "Uso Disco Root (/)" "$uso_disco"
    printf "%-22s: %s%%\n" "Inodes Root (/)" "$inodes_disco"
    printf "%-22s: %s\n" "Tempo Ligado" "$tempo_ligado"
    echo
    echo "[ REDE ($iface) ]"
    printf "%-22s: %s MB\n" "Rx (Recebido)" "$rx_mb"
    printf "%-22s: %s MB\n" "Tx (Transmitido)" "$tx_mb"
    echo
    read -rp "Press ENTER "
}

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
        "Explicações"
        "Tarefas"
        "Diagnósticos"
        "Cheat Sheet"
        "IPs"
        "Instruções"
        "Logs"
        "Feedback"
        "Dashboard"
    )

    selecionar_menu "${OPCOES[@]}"
    OPCAO=$?

    if [[ $OPCAO -eq 255 ]]; then
        clear; break
    fi


    case $OPCAO in
        0) menu_turnos ;;
        1) registrar_atividade ;;
        2) menu_artigos ;;
        3) menu_estudos ;;
        4) ls_tarefas ;;
        5) menu_diagnosticos ;;
        6) menu_cheatsheet ;;
        7) menu_ips ;;
        8) listar_passos ;;
        9) menu_logs ;;
        10) menu_feedback ;;
        11) dashboard ;;
    esac
done