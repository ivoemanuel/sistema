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

ARQ_ARTIGOS="$DIR_ARTIGOS/artigos.txt"
ARQ_DIAGNOSTICOS="$DIR_DIAGNOSTICOS/diagnosticos.txt"
ARQ_AFAZERES="$DIR_AFAZERES/afazeres.txt"
ARQ_USUARIOS="$DIR_FEEDBACK/usuarios.txt"

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
    # Arquivos
    touch "$ARQ_ARTIGOS"
    touch "$ARQ_AFAZERES"
    touch "$ARQ_DIAGNOSTICOS"
    touch "$ARQ_USUARIOS"

    # add $USUARIO=user em usuarios.txt para o feedback ficar com o nome da pessoa, para isso teremos que mudar 'user' para o nome que queremos que apareça
    if ! grep -q "^${USUARIO}=" "$ARQ_USUARIOS" 2>/dev/null; then
        echo "${USUARIO}=user" >> "$ARQ_USUARIOS"
    fi
} 

# ==========================================
# MENU DE NAVEGAÇÂO
# ==========================================

selecionar_menu() {
    local COR_DESTAQUE="\e[48;2;138;43;226m" RESET="\e[0m" 
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

    local TIPO CATEGORIA ATIVIDADE MARCADOR FEEDBACK USUARIO_LOWER ARQ_FEEDBACK_USUARIO

    selecionar_menu "${OPCOES[@]}"
    local TIPO=$?

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
    read -e -rp "Descreva o que foi feito: " ATIVIDADE

    if [ -z "$ATIVIDADE" ]; then
        echo
        echo "A atividade não pode estar vazia."
        read -rp "Pressione ENTER para voltar..."
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
        local OPCOES=(
            "Adicionar artigo"
            "Listar artigos"
            "Buscar artigo"
            "Voltar"
        )

        selecionar_menu "${OPCOES[@]}" 
        
        local OPCAO=$?
        case $OPCAO in
            0) adicionar_artigo ;;
            1) listar_artigos ;;
            2) pesquisar_artigo ;;
            3) break;;
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
        local OPCOES=(
            "Nova explicação"
            "Abrir explicação"
            "Pesquisar explicações"
            "Voltar"
	    )
        
        selecionar_menu "${OPCOES[@]}"
        
        local OPCAO=$?
        case $OPCAO in
            0) nova_explicacao ;;
            1) abrir_explicacao ;;
            2) pesquisar_explicacao ;;
            3) break ;;
        esac
    done
}

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
        local OPCOES=(
            "Adicionar tarefa"
            "Listar tarefas"
            "Voltar"
        )

        selecionar_menu "${OPCOES[@]}"
    
        local OPCAO=$?
        case "$OPCAO" in
        
            0) add_tarefa ;;
            1) ls_tarefas ;;
            2) break ;;
    
        esac
    done
}

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
            if [[ ! "$CORRIGIR" =~ ^[nN]$ ]]; then
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
        
        local OPCOES=(
            "Adicionar diagnóstico"
            "Abrir diagnóstico"
            "Listar diagnósticos"
            "Voltar"
        )

        selecionar_menu "${OPCOES[@]}"
        
        local OPCAO=$?
        case $OPCAO in
            0) add_diagnostico ;;
            1) abrir_diagnostico ;;
            2) ls_diagnostico ;;
            3) break ;;
        esac
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
        echo "Confirme se o caminho está correto"
        read -rp "Pressione ENTER para voltar..."
        return
    fi

    echo
    read -rp "Deseja acompanhar em tempo real? [s/N]: " OPCAO
    if [[ "$OPCAO" =~ ^[sS]$ ]]; then
        clear
        echo "Pressione Ctrl+C para sair do acompanhamento em tempo real"
        read -rp "Pressione ENTER para continuar..."
        tail -fn 30 "$CAMINHO"
    else
        LINHAS=$(perguntar_linhas)
        clear
        tail -n "$LINHAS" "$CAMINHO"
        echo
        read -rp "Pressione ENTER para voltar..."
    fi
}

exibir_log_journalctl() {
    local UNIT=$1 LINHAS

    echo
    read -rp "Deseja acompanhar em tempo real? [s/N]: " OPCAO
    if [[ "$OPCAO" =~ ^[sS]$ ]]; then
        clear
        echo "Pressione Ctrl+C para sair do acompanhamento em tempo real"
        read -rp "Pressione ENTER para continuar..."
        sudo journalctl -u "$UNIT" -fn 30
    else
        LINHAS=$(perguntar_linhas)
        clear
        sudo journalctl -u "$UNIT" -n "$LINHAS"
        echo
        read -rp "Pressione ENTER para voltar..."
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
            "Voltar"
        )

        selecionar_menu "${OPCOES[@]}"
        local ESCOLHA=$?

        case $ESCOLHA in
            0) exibir_log_arquivo "$CAMINHO_LOG" ;;
            1)
                clear
                (sudo "$CAMINHO_SCRIPT")
                echo
                read -rp "Pressione ENTER para voltar..." ;;
            2) break ;;
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
            "Voltar"
        )

        selecionar_menu "${OPCOES[@]}"
        
        local ESCOLHA="$?"
        case $ESCOLHA in
            0) menu_script "LIMPEZA" "/var/log/limpeza/limpeza-atual.log" "/scripts/auto-remove.sh" ;;
            1) menu_script "STORAGE" "/var/log/backupsamba/COLOCAR CAMINHO CERTO" "/scripts/storage.sh" ;;
            2) menu_script "MONITORAMENTO" "/var/log/minipc-monitoring/ultimo-monitoramento.log" "/scripts/monitoramento.sh" ;;
            3) break ;;
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
            "Voltar"
        )

        selecionar_menu "${OPCOES[@]}"

        local ESCOLHA=$?
        case $ESCOLHA in
            0) exibir_log_journalctl "gotify" ;;
            1) break ;;
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
            read -rp "Pressione ENTER para voltar..."
            return
        fi

        OPCOES=()
        ARQUIVOS_ENCONTRADOS=()

        while IFS= read -r NOME_ARQUIVO; do
            if [[ -z "$NOME_ARQUIVO" ]]; then continue; fi
            OPCOES+=("$(basename "$NOME_ARQUIVO")")
            ARQUIVOS_ENCONTRADOS+=("$NOME_ARQUIVO")
        done < <(find /var/log/samba -maxdepth 1 -type f | sort)

        OPCOES+=("Voltar")
        selecionar_menu "${OPCOES[@]}"

        ESCOLHA=$?

        if [[ "$ESCOLHA" -eq $((${#OPCOES[@]} - 1 )) ]]; then
            break
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
            "Voltar"
        )

        selecionar_menu "${OPCOES[@]}"
        
        local ESCOLHA=$?
        case "$ESCOLHA" in
            0) exibir_log_journalctl "smbd" ;;
            1) ls_logs_samba ;;
            2) break ;;
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

    read -rp "Pressione ENTER para voltar..."
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
            "Voltar"
        )

        selecionar_menu "${OPCOES[@]}"

        local ESCOLHA="$?"
        case "$ESCOLHA" in
            0) exibir_log_journalctl "fail2ban" ;;
            1) exibir_log_arquivo "/var/log/fail2ban.log" ;;
            2) status_fail2ban ;;
            3) break ;;
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
            "Voltar"
        )
        
        selecionar_menu "${OPCOES[@]}"
        
        local ESCOLHA="$?"
        case $ESCOLHA in
            0) menu_scripts ;;
            1) menu_samba ;;
            2) menu_fail2ban ;;
            3) menu_gotify ;;
            4) break ;;
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

        OPCOES+=("Voltar")
        selecionar_menu "${OPCOES[@]}"
        
        ESCOLHA="$?"
        if [[ "$ESCOLHA" -eq $(( ${#OPCOES[@]} - 1 )) ]]; then
            break
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
        read -rp "Pressione ENTER para gerar o link e abrir no WhatsApp..."

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
        
        local ESCOLHA=$?
        case "$ESCOLHA" in
            0) gerar_feedback ;;
            1) editar_feedback ;;
            2) enviar_feedback_wpp ;;
            3) break ;;
        esac
    done
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
