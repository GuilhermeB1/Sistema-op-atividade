#!/bin/bash

# Definições de nomes de arquivos e diretórios
LOG_DIR="process_logs"
LOG_FILE="$LOG_DIR/process_actions.log"
OUTPUT_FILE="interpreted_process_actions.log"

# Verifica se o diretório de logs existe
if [ ! -d "$LOG_DIR" ]; then
    echo "Erro: O diretório de logs '$LOG_DIR' não foi encontrado!"
    echo "Certifique-se de que o script de coleta de logs foi executado corretamente."
    exit 1
fi

# Verifica se o arquivo de log unificado existe
if [ ! -f "$LOG_FILE" ]; then
    echo "Erro: O arquivo de log '$LOG_FILE' não foi encontrado!"
    echo "Certifique-se de que o script de coleta de logs foi executado corretamente."
    exit 1
fi

echo "===================================================="
echo "          Interpretação de Ações do Processo         "
echo "===================================================="
echo "Este script irá:"
echo "1. Ler o arquivo de log unificado '$LOG_FILE'."
echo "2. Analisar e interpretar as ações capturadas."
echo "3. Gerar um relatório detalhado em '$OUTPUT_FILE'."
echo
echo "Por favor, aguarde enquanto o arquivo é processado..."
echo "----------------------------------------------------"

# Contadores de categorias
count=0
syscall_count=0
file_activity_count=0
network_activity_count=0
process_management_count=0
memory_management_count=0
other_activity_count=0

# Função para interpretar o log unificado
interpret_log() {
    echo "Relatório de Ações do Processo - $(date)" > "$OUTPUT_FILE"
    echo "========================================" >> "$OUTPUT_FILE"
    
    while IFS= read -r line; do
        count=$((count + 1))
        
        # Interpretar chamadas de sistema (System Calls)
        if [[ $line =~ open|read|write|close|lseek|stat|fstat|lstat ]]; then
            echo -e "[File I/O System Call] $line" >> "$OUTPUT_FILE"
            echo -e " - Descrição: Chamada de sistema relacionada a operações de entrada/saída de arquivos." >> "$OUTPUT_FILE"
            syscall_count=$((syscall_count + 1))

        elif [[ $line =~ socket|connect|accept|send|recv|bind|listen ]]; then
            echo -e "[Network System Call] $line" >> "$OUTPUT_FILE"
            echo -e " - Descrição: Chamada de sistema relacionada a operações de rede." >> "$OUTPUT_FILE"
            network_activity_count=$((network_activity_count + 1))

        elif [[ $line =~ fork|execve|wait|exit|kill ]]; then
            echo -e "[Process Management System Call] $line" >> "$OUTPUT_FILE"
            echo -e " - Descrição: Chamada de sistema relacionada ao gerenciamento de processos." >> "$OUTPUT_FILE"
            process_management_count=$((process_management_count + 1))

        elif [[ $line =~ mmap|munmap|brk|mprotect ]]; then
            echo -e "[Memory Management System Call] $line" >> "$OUTPUT_FILE"
            echo -e " - Descrição: Chamada de sistema relacionada ao gerenciamento de memória." >> "$OUTPUT_FILE"
            memory_management_count=$((memory_management_count + 1))
        
        # Interpretar logs do lsof (Atividades de arquivo/rede)
        elif [[ $line =~ REG|DIR|FIFO|SOCK|IPv4 ]]; then
            echo -e "[File/Network Activity] $line" >> "$OUTPUT_FILE"
            echo -e " - Descrição: Atividade de arquivo ou rede capturada pelo lsof." >> "$OUTPUT_FILE"
            file_activity_count=$((file_activity_count + 1))
        
        else
            echo -e "[Outras Ações] $line" >> "$OUTPUT_FILE"
            echo -e " - Descrição: Ação não categorizada ou desconhecida." >> "$OUTPUT_FILE"
            other_activity_count=$((other_activity_count + 1))
        fi
        echo -e "----------------------------------------" >> "$OUTPUT_FILE"

    done < "$LOG_FILE"
    
    # Resumo com estatísticas
    echo "====================================================" >> "$OUTPUT_FILE"
    echo "Resumo da Interpretação:" >> "$OUTPUT_FILE"
    echo " - Total de ações processadas: $count" >> "$OUTPUT_FILE"
    echo " - Chamadas de sistema relacionadas a I/O de arquivos: $syscall_count" >> "$OUTPUT_FILE"
    echo " - Chamadas de sistema relacionadas a operações de rede: $network_activity_count" >> "$OUTPUT_FILE"
    echo " - Chamadas de sistema relacionadas ao gerenciamento de processos: $process_management_count" >> "$OUTPUT_FILE"
    echo " - Chamadas de sistema relacionadas ao gerenciamento de memória: $memory_management_count" >> "$OUTPUT_FILE"
    echo " - Outras atividades capturadas (arquivo/rede): $file_activity_count" >> "$OUTPUT_FILE"
    echo " - Outras ações não categorizadas: $other_activity_count" >> "$OUTPUT_FILE"
    echo "====================================================" >> "$OUTPUT_FILE"
}

# Inicia a interpretação do log unificado
interpret_log

# Mensagem de conclusão para o usuário
echo "===================================================="
echo "Interpretação concluída!"
echo "Um total de $count ações foram processadas."
echo " - Chamadas de sistema relacionadas a I/O de arquivos: $syscall_count"
echo " - Chamadas de sistema relacionadas a operações de rede: $network_activity_count"
echo " - Chamadas de sistema relacionadas ao gerenciamento de processos: $process_management_count"
echo " - Chamadas de sistema relacionadas ao gerenciamento de memória: $memory_management_count"
echo " - Outras atividades capturadas (arquivo/rede): $file_activity_count"
echo " - Outras ações não categorizadas: $other_activity_count"
echo
echo "O relatório completo está disponível no arquivo: $OUTPUT_FILE"
echo "===================================================="
