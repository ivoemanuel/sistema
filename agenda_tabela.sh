#!/bin/bash
# ============================================================
#  MÓDULO DE TAREFAS — visualização em tabela navegável
#  Requer terminal UTF-8. ARQ_AFAZERES deve estar definido
#  no restante do projeto (ex: ARQ_AFAZERES="$HOME/.afazeres.db")
#
#  Formato do arquivo (5 campos, separados por "|"):
#    ID|STATUS|PRIORIDADE|DESCRICAO|PRAZO
#    STATUS agora tem 3 estados: ABERTA | ANDAMENTO | CONCLUIDA
# ============================================================

# --------------------- Cores e larguras ---------------------
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

# --------------------- Funções auxiliares ---------------------

repetir() {
    # repetir <quantidade> <caractere-utf8>  (evita 'tr', que quebra multibyte)
    local n="$1" ch="$2" out=""
    for (( k=0; k<n; k++ )); do out+="$ch"; done
    printf '%s' "$out"
}

centralizar() {
    # centralizar "texto" largura
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
    local texto="$1" largura="$2" falta
    falta=$(( largura - ${#texto} ))
    (( falta < 0 )) && falta=0
    printf '%s%*s' "$texto" "$falta" ''
}

truncar_esq() {
    # truncar_esq "texto" largura  -> alinhado à esquerda, com "…" se estourar
    local texto="$1" largura="$2"
    if (( ${#texto} > largura )); then
        printf '%s' "${texto:0:$((largura-1))}…"
    else
        printf '%-*s' "$largura" "$texto"
    fi
}

# Lê uma tecla (trata setas, backspace e enter)
ler_tecla() {
    local tecla resto
    IFS= read -rsn1 tecla
    if [[ $tecla == $'\x1b' ]]; then
        read -rsn2 -t 0.02 resto
        case "$resto" in
            '[A') echo "CIMA" ;;
            '[B') echo "BAIXO" ;;
            '[C') echo "DIREITA" ;;
            '[D') echo "ESQUERDA" ;;
            *)    echo "ESC" ;;
        esac
    elif [[ $tecla == $'\x7f' || $tecla == $'\x08' ]]; then
        echo "BACKSPACE"
    elif [[ $tecla == "+" ]]; then
        echo "MAIS"
    elif [[ $tecla == "d" || $tecla == "D" ]]; then
        echo "DEL"
    elif [[ -z $tecla ]]; then
        echo "ENTER"
    else
        echo "OUTRO"
    fi
}

# Dado um STATUS, define SIMBOLO e COR_STATUS globais
status_info() {
    case "$1" in
        ANDAMENTO) SIMBOLO="[>]"; COR_STATUS="$COR_AMARELO" ;;
        CONCLUIDA) SIMBOLO="[✓]"; COR_STATUS="$COR_VERDE" ;;
        *)         SIMBOLO="[ ]"; COR_STATUS="$COR_CINZA" ;;
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
    local total=${#IDS[@]}
    local TOPO MEIO BASE
    TOPO="┌──────┬$(repetir $((LARG_TAREFA+2)) ─)┬$(repetir $((LARG_PRIORIDADE+2)) ─)┬$(repetir $((LARG_PRAZO+2)) ─)┐"
    MEIO="├──────┼$(repetir $((LARG_TAREFA+2)) ─)┼$(repetir $((LARG_PRIORIDADE+2)) ─)┼$(repetir $((LARG_PRAZO+2)) ─)┤"
    BASE="└──────┴$(repetir $((LARG_TAREFA+2)) ─)┴$(repetir $((LARG_PRIORIDADE+2)) ─)┴$(repetir $((LARG_PRAZO+2)) ─)┘"
    local largura_interna=$(( ${#TOPO} - 2 ))

    clear
    echo "$TOPO"

    # linha de título com contador [ x/total ]
    local titulo=" LISTA DE TAREFAS" contagem="[ $((SEL+1))/$total ] "
    local espacos=$(( largura_interna - ${#titulo} - ${#contagem} ))
    printf "│%s%*s%s│\n" "$titulo" "$espacos" "" "$contagem"

    echo "$MEIO"
    printf "│  ST  │ %-*s│%s│ %s│\n" "$LARG_TAREFA" "TAREFA" \
        "$(centralizar "PRIORIDADE" $((LARG_PRIORIDADE+1)))" \
        "$(centralizar "PRAZO" $LARG_PRAZO)"
    echo "$MEIO"

    local i ID STATUS PRIOR DESC PRAZO PONTEIRO col_st texto_tarefa texto_prior texto_prazo cor_prior
    for (( i=0; i<total; i++ )); do
        ID="${IDS[$i]}"; STATUS="${STATUS_LIST[$i]}"; PRIOR="${PRIORIDADE_LIST[$i]}"
        DESC="${DESCRICOES[$i]}"; PRAZO="${PRAZO_LIST[$i]}"

        status_info "$STATUS"
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
            echo -e "│${COR_SEL}${col_st}${RESET}│ ${texto_tarefa}│${cor_prior}${texto_prior}${RESET} │ ${texto_prazo}│"
        else
            echo -e "│${COR_STATUS}${col_st}${RESET}│ ${texto_tarefa}│${cor_prior}${texto_prior}${RESET} │ ${texto_prazo}│"
        fi
    done

    echo "$BASE"
    echo
    echo "↑ ↓ navegar   ← → status   + adicionar   d excluir   BACKSPACE voltar"
}

# --------------------- Carregamento dos dados ---------------------

carregar_tarefas() {
    IDS=(); STATUS_LIST=(); PRIORIDADE_LIST=(); DESCRICOES=(); PRAZO_LIST=()
    [[ -s "$ARQ_AFAZERES" ]] || return
    local ID STATUS PRIORIDADE DESC PRAZO
    while IFS="|" read -r ID STATUS PRIORIDADE DESC PRAZO || [[ -n "$ID" ]]; do
        ID=$(echo "$ID" | tr -d '\r')
        [[ -z "$ID" ]] && continue
        IDS+=("$ID")
        STATUS_LIST+=("$(echo "$STATUS" | tr -d '\r')")
        PRIORIDADE_LIST+=("$(echo "$PRIORIDADE" | tr -d '\r')")
        DESCRICOES+=("$(echo "$DESC" | tr -d '\r')")
        PRAZO_LIST+=("$(echo "$PRAZO" | tr -d '\r')")
    done < "$ARQ_AFAZERES"
}

salvar_status() {
    # salvar_status <id> <novo_status>
    local id="$1" novo="$2" tmp
    tmp=$(mktemp)
    awk -F'|' -v id="$id" -v status="$novo" 'BEGIN{OFS="|"} { if ($1==id) $2=status; print }' \
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
    local IDS STATUS_LIST PRIORIDADE_LIST DESCRICOES PRAZO_LIST SEL=0 tecla total

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
        read -rp "Press ENTER para voltar..."
        return
    fi

    OPCOES_PRIORIDADE=("Alta" "Média" "Baixa")
    selecionar_menu "${OPCOES_PRIORIDADE[@]}"
    case $? in
        0) PRIORIDADE="ALTA" ;;
        1) PRIORIDADE="MEDIA" ;;
        2) PRIORIDADE="BAIXA" ;;
    esac

    read -e -rp "Prazo (ex: Hoje, Amanhã, 20/09 — ENTER para nenhum): " PRAZO

    if [[ ! -s "$ARQ_AFAZERES" ]]; then
        ID=1
    else
        ID=$(awk -F'|' 'NF >= 1 {print $1}' "$ARQ_AFAZERES" | sort -n | tail -n 1)
        ID=$((ID + 1))
    fi

    echo "$ID|ABERTA|$PRIORIDADE|$DESCRICAO|$PRAZO" >> "$ARQ_AFAZERES"

    echo; echo "Tarefa adicionada com sucesso!"; echo
    read -rp "Press ENTER  "
}

# --------------------- Menu de tarefas (inalterado) ---------------------

menu_tarefas() {
    while true; do
        local OPCOES=("Adicionar tarefa" "Listar tarefas")
        selecionar_menu "${OPCOES[@]}"
        local OPCAO=$?
        [[ $OPCAO -eq 255 ]] && return
        case "$OPCAO" in
            0) add_tarefa ;;
            1) ls_tarefas ;;
        esac
    done
}
