# ==========================================
# PENDÊNCIAS
# ==========================================

listar_pendencias() {
    clear
    echo "========================================"
    echo "           PENDÊNCIAS DO TURNO"
    echo "========================================"
    echo
    

    if [[ ! -s "$PENDENCIAS" ]]; then
        echo "Nenhuma pendência cadastrada."
        echo
        read -rp "Pressione ENTER para voltar..."
        return
    fi

    awk -F'|' '{
        if ($2 == "ABERTA") {
            printf "[ ] [%02d] %s\n", $1, $3
        } else {
            printf "[X] [%02d] %s\n", $1, $3
        }
    }' "$PENDENCIAS"

    echo
    echo "========================================"
    read -rp "Pressione ENTER para voltar..."
}

adicionar_pendencia() {
    clear
    echo "========================================"
    echo "          ADICIONAR PENDÊNCIA"
    echo "========================================"
    echo

    read -rp "Descrição da pendência: " DESCRICAO

    if [[ -z "$DESCRICAO" ]]; then
        echo
        echo "A descrição não pode estar vazia."
        sleep 1.5
        return
    fi

    if [[ ! -s "$PENDENCIAS" ]]; then
        ID=1
    else
        ID=$(awk -F'|' 'NF >= 1 {print $1}' "$PENDENCIAS" | sort -n | tail -n 1)
        ID=$((ID + 1))
    fi

    echo "$ID|ABERTA|$DESCRICAO" | sudo tee -a "$PENDENCIAS" > /dev/null

    echo
    echo "Pendência adicionada com sucesso!"
    sleep 1.5
}

concluir_pendencia() {
    clear
    echo "========================================"
    echo "           CONCLUIR PENDÊNCIA"
    echo "========================================"
    echo

    if [[ ! -s "$PENDENCIAS" ]]; then
        echo "Nenhuma pendência cadastrada."
        echo
        read -rp "Pressione ENTER para voltar..."
        return
    fi

    awk -F'|' '{
        if ($2 == "ABERTA") {
            printf "[ ] [%02d] %s\n", $1, $3
        } else {
            printf "[X] [%02d] %s\n", $1, $3
        }
    }' "$PENDENCIAS"

    echo
    read -rp "Digite o número da pendência a concluir: " ESCOLHA

    if [[ ! "$ESCOLHA" =~ ^[0-9]+$ ]]; then
        echo
        echo "Número inválido."
        sleep 1.5
        return
    fi

    sudo awk -F'|' -v id="$ESCOLHA" 'BEGIN {OFS="|"} { if ($1 == id) $2 = "CONCLUIDA"; print $0 }' "$PENDENCIAS" | sudo tee "$PENDENCIAS.tmp" > /dev/null
    sudo mv "$PENDENCIAS.tmp" "$PENDENCIAS"
    sudo chmod 664 "$PENDENCIAS"

    echo
    echo "Pendência atualizada!"
    sleep 1.5
}

remover_pendencia() {
    clear
    echo "========================================"
    echo "           REMOVER PENDÊNCIA"
    echo "========================================"
    echo

    if [[ ! -s "$PENDENCIAS" ]]; then
        echo "Nenhuma pendência cadastrada."
        echo
        read -rp "Pressione ENTER para voltar..."
        return
    fi

    awk -F'|' '{
        if ($2 == "ABERTA") {
            printf "[ ] [%02d] %s\n", $1, $3
        } else {
            printf "[X] [%02d] %s\n", $1, $3
        }
    }' "$PENDENCIAS"

    echo
    read -rp "Digite o número da pendência a remover: " ESCOLHA

    if [[ ! "$ESCOLHA" =~ ^[0-9]+$ ]]; then
        echo
        echo "Número inválido."
        sleep 1.5
        return
    fi

    sudo awk -F'|' -v id="$ESCOLHA" '$1 != id {print $0}' "$PENDENCIAS" | sudo tee "$PENDENCIAS.tmp" > /dev/null
    sudo mv "$PENDENCIAS.tmp" "$PENDENCIAS"
    sudo chmod 664 "$PENDENCIAS"

    echo
    echo "Pendência removida!"
    sleep 1.5
}

menu_pendencias() {
    while true; do
        clear
        echo "========== PENDÊNCIAS =========="
        echo
        echo "1 - Listar pendências"
        echo "2 - Adicionar pendência"
        echo "3 - Concluir pendência"
        echo "4 - Remover pendência"
        echo "v - Voltar"
        echo

        read -rp "Escolha uma opção: " OPCAO

        case $OPCAO in
            1) listar_pendencias ;;
            2) adicionar_pendencia ;;
            3) concluir_pendencia ;;
            4) remover_pendencia ;;
            [vV]) break ;;
            *) echo -e "\nOpção inválida." ; sleep 1.5 ;;
        esac
    done
}