#!/bin/bash

# Definições de nomes de arquivos e diretórios
LOG_DIR="process_logs"
LOG_FILE="$LOG_DIR/process_actions.log"
OUTPUT_FILE="interpreted_process_actions.log"
MONITOR_DURATION=10  # Duração do monitoramento em segundos

# Função para lidar com a interrupção do script (CTRL+C)
cleanup() {
    echo -e "\nEncerrando o monitoramento..."
    if [ -n "$STRACE_PID" ]; then
        kill $STRACE_PID 2>/dev/null
        wait $STRACE_PID 2>/dev/null
    fi
    if [ -n "$LSOF_PID" ]; then
        kill $LSOF_PID 2>/dev/null
        wait $LSOF_PID 2>/dev/null
    fi
    echo "Monitoramento encerrado. Os logs intermediários foram salvos em '$LOG_DIR'."
    echo "Relatório final disponível em '$OUTPUT_FILE'."
    exit 0
}

# Captura o sinal de interrupção (CTRL+C) e chama a função cleanup
trap cleanup SIGINT

# Verificação se o comando foi executado com root ou com sudo
if [ "$EUID" -ne 0 ]; then
    echo "Por favor, execute como root ou usando sudo."
    exit 1
fi

# Verifica se o strace e o lsof estão instalados
if ! command -v strace &> /dev/null; then
    echo "O comando strace não está instalado. Instalando agora..."
    apt-get install -y strace || yum install -y strace || zypper install -y strace
fi

if ! command -v lsof &> /dev/null; then
    echo "O comando lsof não está instalado. Instalando agora..."
    apt-get install -y lsof || yum install -y lsof || zypper install -y lsof
fi

# Solicita ao usuário o PID do processo que ele deseja monitorar
echo "Digite o PID do processo que você deseja monitorar:"
read PID

# Verifica se o PID é um número
if ! [[ "$PID" =~ ^[0-9]+$ ]]; then
    echo "PID inválido. Deve ser um número."
    exit 1
fi

# Verifica se o processo está em execução
if ! ps -p $PID > /dev/null; then
   echo "O processo com PID $PID não está em execução."
   exit 1
fi

# Cria o diretório para armazenar os logs intermediários
mkdir -p "$LOG_DIR"

# Inicia o rastreamento das system calls do processo por 10 segundos
echo "Iniciando rastreamento das ações do processo com PID $PID por $MONITOR_DURATION segundos..."
timeout $MONITOR_DURATION strace -p $PID -ff -o "$LOG_DIR/strace.log" &
STRACE_PID=$!

# Inicia o rastreamento das ações no sistema de arquivos e rede por 10 segundos
timeout $MONITOR_DURATION lsof -p $PID -r1 > "$LOG_DIR/lsof.log" &
LSOF_PID=$!

# Espera até que os processos de monitoramento sejam encerrados
wait $STRACE_PID
wait $LSOF_PID

# Mesclando e interpretando logs
echo "Unificando logs do strace e lsof para gerar um relatório abrangente..."

cat "$LOG_DIR/strace.log"* "$LOG_DIR/lsof.log" > "$LOG_FILE"

# Função para interpretar o log unificado
interpret_log() {
    echo "Relatório de Ações do Processo - $(date)" > "$OUTPUT_FILE"
    echo "========================================" >> "$OUTPUT_FILE"
    
    count=0
    
    while IFS= read -r line; do
        count=$((count + 1))
        
        # Interpretar logs do strace
        if [[ $line =~ open|read|write|close|fork|execve|socket|connect ]]; then
            echo -e "[System Call] $line" >> "$OUTPUT_FILE"
        
        # Interpretar logs do lsof
        elif [[ $line =~ REG|DIR|FIFO|SOCK|IPv4 ]]; then
            echo -e "[File/Network Activity] $line" >> "$OUTPUT_FILE"
        
        else
            echo -e "[Outras Ações] $line" >> "$OUTPUT_FILE"
        fi

    done < "$LOG_FILE"
    
    echo "Interpretação concluída. Um total de $count ações foram processadas."
    echo "O relatório completo está disponível no arquivo: $OUTPUT_FILE"
    echo "========================================"
}

# Inicia a interpretação do log unificado
interpret_log

# Cleanup final (para garantir que todos os processos sejam finalizados corretamente)
cleanup
