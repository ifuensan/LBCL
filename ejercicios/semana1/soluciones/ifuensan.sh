#!/bin/bash

# Variables de configuración
URL_BTC_CORE_BASE="https://bitcoincore.org/bin/"
ARCHIVO_LOCAL=""
SHA256_LOCAL=""
CORE_VERSION=""
WORK_DIR="./work_dir/"
DIREC_MINERIA=""


imprimir_banner(){
    echo -e "\033[1;31m
    ██╗███████╗██╗   ██╗███████╗███╗   ██╗███████╗ █████╗ ███╗   ██╗                                                                   
    ██║██╔════╝██║   ██║██╔════╝████╗  ██║██╔════╝██╔══██╗████╗  ██║                                                                   
    ██║█████╗  ██║   ██║█████╗  ██╔██╗ ██║███████╗███████║██╔██╗ ██║                                                                   
    ██║██╔══╝  ██║   ██║██╔══╝  ██║╚██╗██║╚════██║██╔══██║██║╚██╗██║                                                                   
    ██║██║     ╚██████╔╝███████╗██║ ╚████║███████║██║  ██║██║ ╚████║                                                                   
    ╚═╝╚═╝      ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝                                                                   

    \033[0m"
    echo -e "                                                                                                      
    ███████╗     ██╗███████╗██████╗  ██████╗██╗ ██████╗██╗ ██████╗      ██╗                                                            
    ██╔════╝     ██║██╔════╝██╔══██╗██╔════╝██║██╔════╝██║██╔═══██╗    ███║                                                            
    █████╗       ██║█████╗  ██████╔╝██║     ██║██║     ██║██║   ██║    ╚██║                                                            
    ██╔══╝  ██   ██║██╔══╝  ██╔══██╗██║     ██║██║     ██║██║   ██║     ██║                                                            
    ███████╗╚█████╔╝███████╗██║  ██║╚██████╗██║╚██████╗██║╚██████╔╝     ██║                                                            
    ╚══════╝ ╚════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝ ╚═════╝╚═╝ ╚═════╝      ╚═╝                                                            
                                                                                                                                    
    ██╗     ██╗██████╗ ██████╗ ███████╗██████╗ ██╗ █████╗     ██████╗ ███████╗    ███████╗ █████╗ ████████╗ ██████╗ ███████╗██╗  ██╗██╗
    ██║     ██║██╔══██╗██╔══██╗██╔════╝██╔══██╗██║██╔══██╗    ██╔══██╗██╔════╝    ██╔════╝██╔══██╗╚══██╔══╝██╔═══██╗██╔════╝██║  ██║██║
    ██║     ██║██████╔╝██████╔╝█████╗  ██████╔╝██║███████║    ██║  ██║█████╗      ███████╗███████║   ██║   ██║   ██║███████╗███████║██║
    ██║     ██║██╔══██╗██╔══██╗██╔══╝  ██╔══██╗██║██╔══██║    ██║  ██║██╔══╝      ╚════██║██╔══██║   ██║   ██║   ██║╚════██║██╔══██║██║
    ███████╗██║██████╔╝██║  ██║███████╗██║  ██║██║██║  ██║    ██████╔╝███████╗    ███████║██║  ██║   ██║   ╚██████╔╝███████║██║  ██║██║
    ╚══════╝╚═╝╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝    ╚═════╝ ╚══════╝    ╚══════╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝
    "
    sleep 2                                                                                                   
}

actualizar_paquetes() {
    echo "Actualizando paquetes de sistema operativo..."
    # Actualizar la lista de paquetes
    apt update > /dev/null 2>&1

    # Instalar o actualizar los paquetes especificados
    apt install -y bc jq autoconf file gcc libc-dev make g++ pkgconf re2c git libtool automake gcc xxd curl wget > /dev/null 2>&1

    # Verificar el código de salida del último comando
    if [ $? -eq 0 ]; then
        echo "La actualización/instalación de paquetes fue exitosa."
    else
        echo "Hubo un error durante la actualización/instalación de paquetes."
        exit 1
    fi
}


descargar_binarios_bitcoin_core() {
    # Crear el nuevo directorio de TRABAJO si no existe
    mkdir -p "$WORK_DIR" || exit 1

    # Cambiar al nuevo directorio
    cd "$WORK_DIR" || exit 1

    # Obtener la lista de versiones desde la URL
    lista_versiones=$(curl -s "${URL_BTC_CORE_BASE}" | grep -oP 'bitcoin-core-\S+/' | awk -F'[-/]' '{print $3}'  | sort -Vr)
    # Obtener la última versión
    ultima_version=$(echo "${lista_versiones}" | head -n 1)

    CORE_VERSION="$ultima_version"

    if [ -z "${ultima_version}" ]; then
        echo "No se pudo determinar la última versión de Bitcoin Core."
        exit 1
    fi

    echo "La última versión de Bitcoin Core es: ${ultima_version}"

    # Construir la ruta del archivo a descargar
    url_descarga="${URL_BTC_CORE_BASE}bitcoin-core-${ultima_version}/"
    archivo_remoto="${url_descarga}bitcoin-${ultima_version}-x86_64-linux-gnu.tar.gz" 
    archivo_sha256sums="${url_descarga}SHA256SUMS"
    ARCHIVO_LOCAL="./bitcoin-${ultima_version}-x86_64-linux-gnu.tar.gz"
    SHA256_LOCAL="./SHA256SUMS"

    # Verificar si el archivo Bitcoin Core ya existe
    if [ -e "${ARCHIVO_LOCAL}" ]; then
        printf "El archivo de Bitcoin Core ya existe. No es necesario volver a descargar.\n"
    else
        printf "Descargando desde: %s\n" "$url_descarga"
        # Descargar el archivo
        wget --progress=bar:force:noscroll "${archivo_remoto}"
        # Verificar el código de salida de wget
        if [ $? -eq 0 ]; then
            echo "Descarga exitosa de Bitcoin Core."
        else
            echo "Error durante la descarga de Bitcoin Core."
            exit 1
        fi
    fi
    # Verificar si el archivo SHA256SUMS ya existe
    if [ -e "${SHA256_LOCAL}" ]; then
        printf "El archivo de SHA256SUMS ya existe. No es necesario volver a descargar.\n"
    else
        printf "Descargando desde: %s\n" "$archivo_sha256sums"
        # Descargar el archivo SHA
        wget --progress=bar:force:noscroll "${archivo_sha256sums}"
        # Verificar el código de salida de wget
        if [ $? -eq 0 ]; then
            echo "Descarga exitosa de SHA256SUMS."
        else
            echo "Error durante la descarga de SHA256SUMS."
            exit 1
        fi
    fi

    # Verificar si el archivo SHA256SUMS.asc ya existe
    if [ -e "${SHA256_LOCAL}.asc" ]; then
        printf "El archivo de SHA256SUMS.asc ya existe. No es necesario volver a descargar.\n"
    else
        printf "Descargando desde: %s\n" "$archivo_sha256sums".asc
        # Descargar el archivo SHA
        wget --progress=bar:force:noscroll "${archivo_sha256sums}".asc
        # Verificar el código de salida de wget
        if [ $? -eq 0 ]; then
            echo "Descarga exitosa de SHA256SUMS.asc"
        else
            echo "Error durante la descarga de SHA256SUMS.asc"
            exit 1
        fi
    fi
}

comprobar_hashes_binarios() {
    nombre_archivo=$(basename "$ARCHIVO_LOCAL")
    hash_bitcoin_core=$(grep "${nombre_archivo}" "${SHA256_LOCAL}" | awk '{print $1}')
    hash_bitcoin_core_command=$(sha256sum --ignore-missing --check ${SHA256_LOCAL})
    echo "hash_bitcoin_core: ${hash_bitcoin_core}"
    echo "hash_bitcoin_core_command: ${hash_bitcoin_core_command}"
    # Verificar si hash_bitcoin_core contiene algo
    if [ -n "$hash_bitcoin_core" ]; then
        echo "El hash de ${nombre_archivo} es: $hash_bitcoin_core"
        # Calcular el hash SHA256 del archivo
        hash_archivo_local=$(sha256sum "$ARCHIVO_LOCAL" | awk '{print $1}')
        # Comparar los hashes
        if [ "$hash_bitcoin_core" = "$hash_archivo_local" ]; then
            echo "¡Verificación exitosa del hash!"
            #Comprobar la firma gpg
            git clone https://github.com/bitcoin-core/guix.sigs
            gpg --import guix.sigs/builder-keys/*
            gpg --verify ${SHA256_LOCAL}.asc
            if [ $? -eq 0 ]; then
                echo "¡Verificación exitosa de la firma binaria!"
            else
                echo "Error durante la verificación de la firma binaria"
                exit 1
            fi        
        else
            echo "¡Advertencia! El hash extraído no coincide con el hash del archivo."
            exit 1
        fi
    else
        echo "No se encontró el hash para ${nombre_archivo} en el archivo SHA256_LOCAL."
        exit 1
    fi
}

# Función para copiar binarios descargados a /usr/local/bin/
copiar_binarios_descargados() {
    if [ -n "$CORE_VERSION" ]; then
        # Carpeta donde se descomprimen los binarios
        carpeta_destino="/usr/local/bin/"
        #Descromprimimos los binarios
        tar -xzvf "$ARCHIVO_LOCAL" -C .
        if [ $? -eq 0 ]; then
            echo "Descompresión de Binarios exitosa."
        else
            echo "Error durante la descompresión de Binarios"
            exit 1
        fi
        #Creamos el directorio de bitcoin
        install -d "$carpeta_destino"
        # Copiar binarios a la carpeta de destino
        cp -r "./bitcoin-${CORE_VERSION}"/bin/* "$carpeta_destino"
        if [ $? -eq 0 ]; then
            echo "Binarios copiados exitosamente a $carpeta_destino"
        else
            echo "Error durante la copia de los binarios a $carpeta_destino."
            exit 1
        fi
    else
        echo "Error: La variable CORE_VERSION no está definida."
    fi
}

instalar_bitcoin_conf() {
    # Obtener el directorio de inicio del usuario actual o root
    directorio_inicio=$(eval echo ~"$SUDO_USER")

    # Directorio de datos de Bitcoin
    directorio_datos="$directorio_inicio/.bitcoin/"

    # Archivo de configuración
    archivo_conf="$directorio_datos/bitcoin.conf"

    # Crear el directorio si no existe
    if [ ! -d "$directorio_datos" ]; then
        mkdir -p "$directorio_datos"
    fi

    # Crear el archivo de configuración o sobrescribir si ya existe
    cat <<EOF > "$archivo_conf"
regtest=1
fallbackfee=0.0001
server=1
txindex=1
EOF
    echo "Archivo de configuración bitcoin.conf creado en $directorio_datos"
}


iniciar_bitcoind() {
    # Lanzar bitcoind en modo daemon
    bitcoind -daemon

    # Esperar un breve momento para que bitcoind se inicie completamente
    sleep 5

    # Comprobar si bitcoind está ejecutándose
    if pgrep -x "bitcoind" > /dev/null; then
        echo "Bitcoin Core iniciado correctamente." 
        # Comprobar si bitcoin-cli es accesible
        if bitcoin-cli getnetworkinfo > /dev/null 2>&1; then
            echo "bitcoin-cli puede conectar."
        else
            echo "Advertencia: bitcoin-cli no puede conectar. Verifica la configuración."
        fi
    else
        echo "Error: No se pudo iniciar Bitcoin Core. Verifica la configuración o los logs para obtener más detalles."
    fi
}

detener_bitcoind(){
    # Comprobar si bitcoind está ejecutándose
    comando="pgrep -x 'bitcoind'"
    #echo $comando
    #Si hay algo dentro de comando, si no está vacío
    if ! [ -z "$($comando)" ]; then
        echo "Bitcoin Core se encuentra detenido." 
    else
        #Para bitcoind con el cliente
        bitcoin-cli stop
        sleep 5
    fi
}

eliminar_instalacion_previa(){
    # Obtener el directorio de inicio del usuario actual o root
    directorio_inicio=$(eval echo ~"$SUDO_USER")
    # Directorio de datos de Bitcoin
    directorio_datos="$directorio_inicio/.bitcoin/"
    rm -rf $WORK_DIR
    rm -rf $directorio_datos
    echo "Eliminada la instalacion previa..."
}

crear_billeteras(){
    bitcoin-cli -regtest createwallet Miner
    bitcoin-cli -regtest createwallet Trader
    DIREC_MINERIA=$(bitcoin-cli -regtest -rpcwallet=Miner getnewaddress "Recompensa de Minería")
    DIREC_TRADER=$(bitcoin-cli -regtest -rpcwallet=Trader getnewaddress "Recibido")
}

minar_hasta_balance_positivo(){
    #la cantidad de bloques a minar se puede ajustar para que vaya más rápido
    bloques_minar=10
    bloques_minados=0
    # Lanzar generatetoaddress hasta que la cantidad sea mayor que 0
    while true; do
        # Minar un bloque
        bitcoin-cli -regtest -rpcwallet=Miner generatetoaddress "$bloques_minar" "$DIREC_MINERIA"
        # Obtener la cantidad de la dirección de minería
        CANTIDAD=$(bitcoin-cli -regtest -rpcwallet=Miner listunspent 1 9999 "[\"$DIREC_MINERIA\"]" | jq '.[] | .amount')
        # Comprobar si la cantidad es mayor que 0
        if [ -n "$CANTIDAD" ]; then
            echo "Ya existe saldo disponible en $DIREC_MINERIA"
            break
        fi
        ((bloques_minados += bloques_minar))
        echo "Bloques minados $bloques_minados"
        # Esperar un momento antes de la próxima iteración
        # sleep 1
    done
    echo "TODO: Escribir un breve comentario que describa por qué el saldo de la billetera para las recompensas en bloque se comporta de esa manera."
    echo "Miner Wallet Balance:"
    bitcoin-cli -regtest -rpcwallet=Miner getbalances
}

pago_entre_pares(){
    TX_PAR1_A_PAR2=$(bitcoin-cli -regtest -rpcwallet=$1 sendtoaddress "$2" $3)
    echo "Envio $3 Bitcoin de $1 a $2 y tiene este txid: $TX_PAR1_A_PAR2"
    #Minamos un bloque para confirmar la transacción
    echo "Minamos un bloque para confirmar la transacción.."
    bitcoin-cli -regtest -rpcwallet=Miner generatetoaddress 1 "$DIREC_MINERIA"
}

# Function to extract and display information
display_transaction_info() {
    echo "Obtenemos información de $1 de la transacción..."
    json_data=$(bitcoin-cli -regtest -rpcwallet=$1 gettransaction $2)
    txid=$(echo "$json_data" | jq -r '.txid')
    send_amount=$(echo "$json_data" | jq -r '.amount')

    input_amount=$(bitcoin-cli -regtest -rpcwallet=Miner listunspent 1 9999 "[\"${ADDR_MINING}\"]" | jq '.[] | .amount')

    #FEES
    fee=$(echo "$json_data" | jq -r '.fee' | sed 's/-//')
    formated_fees=$(printf "%.8f" "$fee")
    #BLOQUE
    block_height=$(echo "$json_data" | jq -r '.blockheight')

    echo "Obtenemos los datos del cambio..."
    json_change=$(bitcoin-cli -regtest -rpcwallet=Miner listunspent 1 9999 | jq '.[] | select(.label !=  "Recompensa de Minería")')
    change_address=$(echo "$json_change" | jq -r '.address')
    change_amount=$(echo "$json_change" | jq -r '.amount')

    echo "Obtenemos los balances de $1 y de $3..."
    miner_balance=$(bitcoin-cli -regtest -rpcwallet=$1 getbalances) 
    trader_balance=$(bitcoin-cli -regtest -rpcwallet=$3 getbalances)

    echo "- txid: $TX_PAR1_A_PAR2"
    echo "- <De, Cantidad>: $DIREC_MINERIA, $input_amount."
    echo "- <Enviar, Cantidad>: $DIREC_TRADER, ${send_amount#-}."
    echo "- <Cambio, Cantidad>: $change_address, $change_amount."
    echo "- Comisiones: $formated_fees"
    echo "- Bloque: $block_height"
    echo "- Saldo de Miner: $miner_balance"
    echo "- Saldo de Trader: $trader_balance"
}

# Programa principal
#imprimir_banner
detener_bitcoind
eliminar_instalacion_previa
#actualizar_paquetes
descargar_binarios_bitcoin_core
comprobar_hashes_binarios
copiar_binarios_descargados
instalar_bitcoin_conf
iniciar_bitcoind
crear_billeteras
minar_hasta_balance_positivo
pago_entre_pares "Miner" $DIREC_TRADER 20 
display_transaction_info "Miner" $TX_PAR1_A_PAR2 "Trader"

#bitcoin-cli -regtest -rpcwallet=Miner gettransaction 15f43f60e930599fdfc44f646d596c05151880b61cd7f0b85cfa13903935e837
#bitcoin-cli -regtest -rpcwallet=Miner getmempoolentry 15f43f60e930599fdfc44f646d596c05151880b61cd7f0b85cfa13903935e837
#bitcoin-cli -regtest -rpcwallet=Miner getnewaddress "Recompensa de Minería"