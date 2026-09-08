#!/bin/bash

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