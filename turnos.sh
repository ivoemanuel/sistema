#!/bin/bash

# ==========================================
# CONFIGURAÇÕES
# ==========================================

RAIZ="/opt/sisteminha"

PASTA="$RAIZ/registros"
ARTIGOS="$RAIZ/artigos/artigos.txt"
EXPLICACAO="$RAIZ/explicacoes"
DIAGNOSTICOS="$RAIZ/diagnosticos/diagnosticos.txt"
AFAZERES="$RAIZ/afazeres/afazers.txt"

USUARIO=$(whoami)
DATA=$(date '+%d-%m-%Y')
HORA=$(date '+%H:%M')

ARQUIVO="$PASTA/$DATA.txt"

# ==========================================
# SELECIONAR
# ==========================================

selecionar_menu() {

    local OPCOES=("$@")
    local SELECIONADO=0
    local TECLA

    while true; do
        clear

        for i in "${!OPCOES[@]}"; do
            if [[ $i -eq $SELECIONADO ]]; then
                echo "🐧 ${OPCOES[$i]}"
            else
                echo "  ${OPCOES[$i]}"
            fi
        done

        echo
        echo "↑ ↓ navegar | ENTER selecionar"

        IFS= read -rsn1 TECLA

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

        elif [[ "$TECLA" == "" ]]; then
            break
        fi

        if (( SELECIONADO < 0 )); then
            SELECIONADO=$((${#OPCOES[@]} - 1))
        fi

        if (( SELECIONADO >= ${#OPCOES[@]} )); then
            SELECIONADO=0
        fi
    done

    return "$SELECIONADO"
}


# ==========================================
# VERIFICAR E CRIAR ESTRUTURA
# ==========================================

verificar_estrutura() {
    # Pastas
    mkdir -p "$PASTA"
    mkdir -p "$EXPLICACAO"
    mkdir -p "$RAIZ/artigos"
    mkdir -p "$RAIZ/diagnosticos"
    mkdir -p "$RAIZ/afazeres"

    # Arquivos
    sudo touch "$ARTIGOS"
    sudo touch "$AFAZERES"
    sudo touch "$DIAGNOSTICOS"
    sudo touch "$FEEDBACK"
    
    # Garantir permissão de leitura/escrita para o arquivo
    sudo chmod 664 "$ARTIGOS"
    sudo chmod 664 "$AFAZEREs"
    sudo chmod 664 "$DIAGNOSTICOS"
    sudo chmod 664 "$FEEDBACK"
} 

# ==========================================
# CRIAR ARQUIVO DO DIA
# ==========================================

criar_registro() {

    DATA=$(date '+%Y-%m-%d')
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

    clear

    cat "$ARQUIVO"

    echo
    echo "========================================"

    read -rp "Pressione ENTER para voltar..."

}

# ==========================================
# REGISTRAR ATIVIDADE
# ==========================================

registrar_atividade() {

    clear

    echo "========================================"
    echo "        REGISTRAR ATIVIDADE"
    echo "========================================"
    echo

    echo "1 - Rotina"
    echo "2 - Alterações críticas"
    echo "3 - Artigo"
    echo "4 - Explicação"
    echo "5 - Problema"
    echo "6 - Observação"
    echo "v - Voltar"
    echo

    read -rp "Escolha o tipo: " TIPO

    case $TIPO in

        1) CATEGORIA="ROTINA" ;;
        2) CATEGORIA="ALTERACOES" ;;
        3) CATEGORIA="ARTIGOS" ;;
        4) CATEGORIA="EXPLICACOES" ;;
        5) CATEGORIA="PROBLEMAS" ;;
        6) CATEGORIA="OBSERVACOES" ;;

        [vV])
            clear
            return ;;

        *)
            echo
            echo "Opção inválida!"
            sleep 2
            return ;;

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

    echo "[$HORA] | $CATEGORIA | $MARCADOR | $ATIVIDADE" >> "$ARQUIVO"

    echo
    echo "Atividade registrada com sucesso!"
    echo

    read -rp "Pressione ENTER para voltar..."

}

registrar_atividade() {
    while true; do
        clear

        OPCOES=(
            "Rotina"
            "Alterações críticas"
            "Artigo"
            "Explicação"
            "Problema"
            "Observação"
            "Voltar"
        )
}

# ==========================================
# DESCOBRIR ÚLTIMO TURNO
# ==========================================

obter_ultimo_turno() {

    ls -1 "$PASTA"/*.txt 2>/dev/null \
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

    clear

    echo "========================================"
    echo "             HISTÓRICO"
    echo "========================================"
    echo

    if ! ls "$PASTA"/*.txt >/dev/null 2>&1; then

        echo "Nenhum registro encontrado."

    else

        ls -1 "$PASTA"/*.txt \
            | xargs -n 1 basename \
            | sort

    fi

    echo
    echo "========================================"

    read -rp "Pressione ENTER para voltar..."

}

# ==========================================
# ARTIGOS
# ==========================================

adicionar_artigo(){
    clear
    echo
    echo "========== ADICIONAR ARTIGO =========="
    echo

    read -rp "Título: " TITULO
    read -rp "Link: " LINK

    if [[ -z "$TITULO" || -z "$LINK" ]]; then
        echo
        echo "Título e link não podem estar vazios."
        return
    fi

    if [[ ! -s "$ARTIGOS" ]]; then
        ID=1
    else
        ID=$(awk -F'|' 'NF >= 1 {print $1}' "$ARTIGOS" | sort -n | tail -n 1)
        ID=$((ID + 1))
    fi

    echo "$ID|$TITULO|$LINK" | sudo tee -a "$ARTIGOS" > /dev/null
    
    echo
    echo "Artigo adicionado com sucesso!"
    read -rp "Pressione ENTER para voltar..."
}

listar_artigos() {
    clear
    echo
    echo "========== NÃO ACREDITE EM MIM... PESQUISE! =========="
    echo

    if [[ ! -s "$ARTIGOS" ]]; then
        echo "Nenhum artigo cadastrado."
        sleep 2
        return
    fi

    awk -F'|' '{
        printf "[%02d] %s\n", $1, $2
        printf "     %s\n\n", $3
    }' "$ARTIGOS"
    
    read -rp "Pressione ENTER para voltar..."

}

pesquisar_artigo(){
    clear
    echo
    echo "========== BUSCAR ARTIGO =========="
    echo

    read -rp "Digite o título ou palavra-chave: " PESQUISA

    if [[ -z "$PESQUISA" ]]; then
        echo
        echo "Pesquisa vazia."
        echo
        sleep 2
        return
    fi

    RESULTADO=$(grep -i "$PESQUISA" "$ARTIGOS")

    if [[ -z "$RESULTADO" ]]; then
        echo
        echo "Nenhum artigo encontrado."
        echo
        sleep 2
        return
    fi

    echo
    echo "$RESULTADO" | awk -F'|' '{
        printf "[%02d] %s\n", $1, $2
        printf "     %s\n\n", $3
    }'

    read -rp "Pressione ENTER para voltar..."

}

menu_artigos() {
    while true; do
        clear
        
        OPCOES=(
            "Adicionar artigo"
            "Listar artigos"
            "Buscar artigo"
            "Voltar"
        )

        selecionar_menu "${OPCOES[@]}" 
        OPCAO=$?

        case $OPCAO in
            0) adicionar_artigo ;;
            1) listar_artigos ;;
            2) pesquisar_artigo ;;
            3) break;;
        esac
    done
}

# ==========================================
# EXPLICAÇÕES
# ==========================================

nova_explicacao(){
    echo
    echo "========== EXPLICAÇÕES =========="
    echo

    read -rp "Título: " TITULO

    if [[ -z "$TITULO" ]]; then
        echo "O título não pode estar vazio"
        sleep 2
        return
    fi

    echo
    echo "Digite o conteúdo da explicação"
    echo "Quando terminar digite 'FIM' em uma linha separada "
    echo

    CONTEUDO=""

    while true; do
        # [CORREÇÃO] Inclusão de IFS= para não quebrar a indentação e os espaços originais da linha lida
        IFS= read -r LINHA

        if [[ "$LINHA" == "FIM" ]]; then
            break
        fi

        CONTEUDO+="$LINHA"$'\n'
    done

    if [[ -z "${CONTEUDO//[$'\n\r ']/}" ]]; then
        echo
        echo "O conteúdo não pode estar vazio."
        sleep 2
        return
    fi

    NOME=$(echo "$TITULO" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
    ARQUIVO_EXPLICACAO="$EXPLICACAO/${DATA}-${NOME}.txt"

    {
        DATA=$(date '+%Y-%m-%d')
        echo "========================================="
        echo "               EXPLICAÇÕES"
        echo "========================================="
        echo
        echo "TÍTULO: $TITULO"
        echo "DATA: $DATA"
        echo "USUÁRIO: $USUARIO"
        echo
        echo "========================================="
        echo
        printf "%s" "$CONTEUDO"
    } > "$ARQUIVO_EXPLICACAO"

    echo
    echo "Anotação salva com sucesso!"
    echo "Arquivo: $ARQUIVO_EXPLICACAO"
    sleep 2
}

abrir_explicacao(){
    clear
    echo
    echo "========== ABRIR EXPLICAÇÃO =========="
    echo

    ARQUIVOS=$(find "$EXPLICACAO" -maxdepth 1 -type f -name "*.txt" | sort)

    if [[ -z "$ARQUIVOS" ]]; then
        echo
        echo "Nenhuma explicação cadastrada"
        sleep 2
        return
    fi

    NUMERO=1
    declare -a LISTA_ARQUIVOS

    while IFS= read -r ARQUIVO; do
        LISTA_ARQUIVOS[$NUMERO]="$ARQUIVO"

        TITULO=$(grep "^TÍTULO:" "$ARQUIVO" | sed 's/^TÍTULO: //')
        DATA_EXPLICACAO=$(grep "^DATA:" "$ARQUIVO" | sed 's/^DATA: //')

        echo "[$NUMERO] $TITULO"
        echo

        ((NUMERO++))
    done <<< "$ARQUIVOS"

    read -rp "Digite o número da explicação: " ESCOLHA

    if [[ ! "$ESCOLHA" =~ ^[0-9]+$ ]]; then
        echo
        echo "Digite um número válido."
        sleep 2
        return
    fi

    if [[ -z "${LISTA_ARQUIVOS[$ESCOLHA]}" ]]; then
        echo
        echo "Explicação não encontrada."
        sleep 2
        return
    fi
    clear
    echo
    cat "${LISTA_ARQUIVOS[$ESCOLHA]}"
    echo "========================================"
    read -rp "Pressione ENTER para voltar..."
}

pesquisar_explicacao(){
    clear
    echo
    echo "========== PESQUISAR EXPLICAÇÃO =========="
    echo

    read -rp "Digite o título ou palavra-chave: " PESQUISA

    if [[ -z "$PESQUISA" ]]; then
        echo
        echo "A Pesquisa não pode estar vazia."
        sleep 2
        return
    fi

    ENCONTRADOS=0
    NUMERO=1

    while IFS= read -r ARQUIVO; do
        
        if grep -qi "$PESQUISA" "$ARQUIVO"; then
            TITULO=$(grep "^TÍTULO:" "$ARQUIVO" | sed 's/^TÍTULO: //')
            DATA_EXPLICACAO=$(grep "^DATA:" "$ARQUIVO" | sed 's/^DATA: //')

            echo "[$NUMERO] $TITULO"
            echo "    Data: $DATA_EXPLICACAO"
            echo "    Arquivo: $(basename "$ARQUIVO")"
            echo

            ((NUMERO++))
            ((ENCONTRADOS++))
        fi

    done < <(find "$EXPLICACAO" -maxdepth 1 -type f -name "*.txt" | sort)

    if [[ $ENCONTRADOS -eq 0 ]]; then
        echo
        echo "Nenhuma explicação encontrada para: $PESQUISA"
        sleep 2
    else
        echo
        echo "Encontradas: $ENCONTRADOS explicação(ões)."
        echo
        read -rp "Pressione ENTER para voltar..."
    fi
}

menu_explicacao(){
    while true; do
        clear
        echo
        echo "========== ESTUDOS =========="
        echo
        echo "1 - Nova explicação"
        echo "2 - Abrir explicação"
        echo "3 - Pesquisar explicações"
        echo "v - Voltar"
        echo

        read -rp "Escolha uma opção: " OPCAO

        case $OPCAO in
        
            1) nova_explicacao ;;
            2) abrir_explicacao ;;
            3) pesquisar_explicacao ;;
            
            [vV]) break ;;
            
            *)
                echo "Opção inválida."
                ;;
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

    read -rp "Título: " TITULO
    if [[ -z "$TITULO" ]]; then
        echo
        echo "O título não pode estar vazio"
        read -rp "Pressione ENTER para voltar..."
        sleep 1
        return
    fi    

    echo
    echo "O que estava acontecendo:"
    echo "Quando terminar digite 'FIM' em uma linha separada"
    echo

    ERRO=""
    while true; do
        IFS= read -r LINHA
        if [[ "$LINHA" == "FIM" ]]; then break; fi
        ERRO+="$LINHA"$'\n'
    done

    if [[ -z "${ERRO//[$'\n\r ']/}" ]]; then
        echo
        echo "O escopo de erro não pode estar vazio"
        sleep 1.5
        return
    fi

    echo
    echo "Explicação:"
    echo "Quando terminar digite 'FIM' em uma linha separada "
    echo

    EXPLICACAO=""
    
    while true; do
        IFS= read -r LINHA 
        if [[ "$LINHA" == "FIM" ]]; then break; fi
        EXPLICACAO+="$LINHA"$'\n'
    done

    if [[ -z "${EXPLICACAO//[$'\n\r ']/}" ]]; then
        echo
        echo "A explicação Não pode estar vazia"
        sleep 1.5
        return
    fi

    echo
    echo "Solução:"
    echo "Quando terminar digite 'FIM' em uma linha separada "
    echo

    SOLUCAO=""
    
    while true; do
        IFS= read -r LINHA
        if [[ "$LINHA" == "FIM" ]]; then break; fi
        SOLUCAO+="$LINHA"$'\n'
    done

    if [[ -z "${SOLUCAO//[$'\n\r ']/}" ]]; then
        echo
        echo "A solução não pode estar vazia"
        sleep 1.5
        return
    fi
    
    {
        DATA=$(date '+%Y-%m-%d')
        echo "================" 
        echo "Data: $DATA"
        echo "Título: $TITULO"
        echo "----------------"
        echo
        echo "O que estava acontecendo:"
        printf "%s" "$ERRO"
        echo
        echo "Explicação:"
        printf "%s" "$EXPLICACAO"
        echo
        echo "Solução:"
        printf "%s" "$SOLUCAO"
        echo
    } | sudo tee -a "$DIAGNOSTICOS" > /dev/null
    
    echo
    echo "Diagnóstico salvo com sucesso!"
    read -rp "Pressione ENTER para voltar..."
    clear

}

abrir_diagnostico(){
    clear
    echo "==================================="
    echo "         ABRIR DIAGNÓSTICO"
    echo "==================================="

    if [[ ! -s "$DIAGNOSTICOS" ]]; then
        echo "Nenhum diagnóstico cadastrado"
        echo
        read -rp "Pressione ENTER para voltar..."
        return
    fi
    
    NUMERO=1

    while IFS= read -r TITULO; do
        TITULO=${TITULO#Título: }

        echo "[$NUMERO] - $TITULO"
        
        ((NUMERO++))

    done < <(grep "^Título:" "$DIAGNOSTICOS")
    echo

    read -rp "Digite o número do diagnóstico: " ESCOLHA

    if ! [[ "$ESCOLHA" =~ ^[0-9]+$ ]]; then
        echo
        echo "Número inválido"
        read -rp "Pressione ENTER para voltar..."
        return
    fi
    
    TOTAL=$(grep -c "^Título:" "$DIAGNOSTICOS")

    if (( ESCOLHA < 1 || ESCOLHA > TOTAL )); then
        echo
        echo "Diagnóstico não encontrado"
        read -rp "Pressione ENTER para voltar..."
        return
    fi
    
    INICIO=$(grep -n "^Título:" "$DIAGNOSTICOS" | sed -n "${ESCOLHA}p" | cut -d: -f1)
    INICIO=$((INICIO - 2))
    if (( INICIO < 1 )); then
        INICIO=1
    fi

    FIM=$(grep -n "^Título:" "$DIAGNOSTICOS" | sed -n "$((ESCOLHA + 1))p" | cut -d: -f1)
    if [[ -n "$FIM" ]]; then
        clear
        FIM=$((FIM - 3))
        sed -n "${INICIO},${FIM}p" "$DIAGNOSTICOS"
    else
        clear
        cat "$DIAGNOSTICOS" | tail -n +"$INICIO"
    fi

    read -rp "Pressione ENTER para voltar..."
    clear
}

ls_diagnostico(){
    clear
    echo "==============="
    echo "DIAGNÓSTICOS"

    if [[ ! -s "$DIAGNOSTICOS" ]]; then
        echo "Nenhum diagnóstico cadastrado"
    else
        cat "$DIAGNOSTICOS"
    fi

    echo
    read -rp "Pressione ENTER para voltar..."
    clear

}

menu_diagnosticos(){
    while true ; do
        clear
        echo
        echo "========== DIAGNÓSTICOS =========="
        echo
        echo "1 - Adicionar diagnóstico"
        echo "2 - Abrir diagnóstico"
        echo "3 - Listar diagnósticos"
        echo "v - Voltar"
        echo
    
        read -rp "Escolha uma opção: " OPCAO

        case $OPCAO in
            1)
                add_diagnostico
                ;;
            2)
                abrir_diagnostico
                ;;
            3)
                ls_diagnostico
                ;;
            v)
                clear
                return
                ;;
            *)  
                echo
                echo "[ ERRO ] Opção inválida"
                sleep 2
                ;;
        esac
        
    done
}

# ==========================================
# LOGS
# ==========================================

menu_logs(){
    while true; do
        clear

        echo "========== LOGS =========="
        echo
        echo "1 - Log de limpeza"
        echo "2 - Log de autenticação"
        echo "3 - Último monitoramento"
        echo "4 - Storage"
        echo "5 - Gotify"
        echo "6 - Kernel"
        echo "v - Voltar"
        echo

        read -rp "Escolha uma opção: " OPCAO

        case $OPCAO in
            1)
                clear
                echo
                echo "========== LOG DE LIMPEZA =========="
                cat /var/log/limpeza/limpeza.log
                read -rp "Pressione ENTER para voltar..."
                ;;

            2)
                clear
                echo
                echo "========== LOG DE AUTENTICAÇÃO =========="
                read -rp "Quantas linhas deseja ver? " LINHAS
                
                # Garante que o valor informado é estritamente numérico
                if [[ ! "$LINHAS" =~ ^[0-9]+$ ]]; then
                    echo "[ INFO ] Entrada inválida. Exibindo 20 linhas por padrão"
                    LINHAS=20
                fi

                sudo tail -n "$LINHAS" /var/log/auth.log
                read -rp "Pressione ENTER para voltar..."
                ;;

            3)
                clear
                echo
                echo "=================================================="
                echo "               ÚLTIMO MONITORAMENTO"
                cat /var/log/minipc-monitoring/ultimo_monitoramento.log
                read -rp "Pressione ENTER para voltar..."
                ;;

            4)
                clear
                echo
                cd /scripts/ && sudo ./storage.sh
                read -rp "Pressione ENTER para voltar..."
                ;;

            5)
                clear
                echo
                #echo "========== GOTIFY =========="
                read -rp "Deseja acompanhar o log em tempo real (s/n)? " OPCAO

                if [[ "$OPCAO" == [sS] ]]; then
                    echo "Pressione 'CTRL + C' quando quiser para o acompanhamento em tempo real"
                    sleep 1.5
                    sudo journalctl -u gotify -fn 30
                else
                    read -rp "Quantas linhas deseja ver? " LINHAS
                
                    # Garante que o valor informado é estritamente numérico
                    if [[ ! "$LINHAS" =~ ^[0-9]+$ ]]; then
                        echo "[ INFO ] Entrada inválida. Exibindo 20 linhas por padrão"
                        LINHAS=20
                    fi

                    sudo journalctl -u gotify -n "$LINHAS"
                fi
                
                ;;
            6)
                clear
                echo
                read -rp "Deseja acompanhar o log em tempo real (s/n)? " OPCAO

                if [[ "$OPCAO" == [sS] ]]; then
                    echo "Pressione 'CTRL + C' quando quiser para o acompanhamento em tempo real"
                    sleep 1.5
                    sudo journalctl -kfn 30
                else
                    read -rp "Quantas linhas deseja ver? " LINHAS
                
                    # Garante que o valor informado é estritamente numérico
                    if [[ ! "$LINHAS" =~ ^[0-9]+$ ]]; then
                        echo "[ INFO ] Entrada inválida. Exibindo 20 linhas por padrão"
                        LINHAS=20
                    fi

                    sudo journalctl -kn "$LINHAS"
                fi
                ;;
                
            [vV]) break ;;

            *)
                echo
                echo "Opção inválida."
                sleep 1.5
                ;;
        esac
    done
}


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

    FEEDBACK="/opt/turnos/feedback.txt"

    {
        echo "Boa noite, pessoal! Segue o feedback do dia de hoje: ($DATA)"
        echo

        grep '| S |' "$ARQUIVO" | while IFS='|' read -r HORA CATEGORIA MARCADOR ATIVIDADE; do
            ATIVIDADE=$(echo "$ATIVIDADE" | sed 's/^ *//')
            echo "- $ATIVIDADE"
        done

        echo
        echo "Bom descanso a todos, até amanhã!"
    } > "$FEEDBACK"

    while true; do

        clear

        echo "========== FEEDBACK =========="
        echo
        cat "$FEEDBACK"
        echo

        read -p "Deseja adicionar algo ao feedback? [s/N]: " ADICIONAR

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
                sed '$d' "$FEEDBACK" | sed '$d' > "$TEMP"

                # Adiciona cada linha como um novo item
                while IFS= read -r LINHA; do
                    if [[ -n "${LINHA//[$'\r ']/}" ]]; then
                        echo "- $LINHA" >> "$TEMP"
                    fi
                done <<< "$ADICIONAL"

                # Adiciona novamente a frase final
                echo >> "$TEMP"
                echo "Bom descanso a todos!" >> "$TEMP"

                mv "$TEMP" "$FEEDBACK"
            fi

            continue
        fi

        break
    done

    clear

    echo "========== FEEDBACK $DATA =========="
    echo
    cat "$FEEDBACK"

    echo
    read -p "Pressione ENTER para voltar ao menu..."
}               

editar_feedback() {
    FEEDBACK="/opt/turnos/feedback.txt"

    if [[ ! -f "$FEEDBACK" ]]; then
        echo
        echo "Ainda não existe um feedback para editar."
        read -p "Pressione ENTER para voltar..."
        return
    fi

    nano "$FEEDBACK"
}
# ==========================================
# MENU PRINCIPAL
# ==========================================

verificar_estrutura
criar_registro

while true; do

    OPCOES=(
        "Ver último turno"
        "Registrar atividade"
        "Ver registro de hoje"
        "Ver histórico"
        "Artigos"
        "Estudos"
        "Logs"
        "Gerar feedback"
        "Editar feedback"
        "Sair"
    )

    selecionar_menu "${OPCOES[@]}"
    OPCAO=$?

    case $OPCAO in
        0) mostrar_ultimo_turno ;;
        1) registrar_atividade ;;
        2) mostrar_hoje ;;
        3) mostrar_historico ;;
        4) menu_artigos ;;
        5) menu_estudos ;;
        6) menu_logs ;;
        7) gerar_feedback ;;
        8) editar_feedback ;;
        9) exit 0 ;;
    esac

done