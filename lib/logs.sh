#!/bin/bash
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
        
        if [[ $OPCAO -eq 255 ]]; then
            return
        fi

        ESCOLHA="$?"
        case $ESCOLHA in
            0) menu_scripts ;;
            1) menu_samba ;;
            2) menu_fail2ban ;;
            3) menu_gotify ;;
            4) break ;;
        esac
    done
}
