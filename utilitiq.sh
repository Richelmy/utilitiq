#!/bin/bash

# --- DANGER ZONE | CUIDADO AMIGUE ISSO AQUI QUEIMA ---
SENHA_MENU="312319"
SENHA_DESTRUICAO="nuke"
DESTINO="/usr/local/bin/utilitiq"
RODAPE_TXT="\n\n*github.com/Richelmy*"

URL_SCRIPT_REMOTO="https://raw.githubusercontent.com/Richelmy/utilitiq/main/utilitiq.sh"

if ! command -v whiptail &> /dev/null; then
    echo "Instalando dependência (whiptail)..."
    sudo apt update && sudo apt install -y whiptail
fi

if [ "$0" != "$DESTINO" ]; then
    echo "Instalando o script no sistema ($DESTINO)..."
    sudo cp "$0" "$DESTINO"
    sudo chown root:root "$DESTINO"
    sudo chmod 755 "$DESTINO"
    
    rm -f "$0"

    echo "Instalação concluída com sucesso! Iniciando..."
    exec "$DESTINO"
    exit 0
fi

verificar_atualizacao() {
    if command -v curl &> /dev/null || command -v wget &> /dev/null; then
        echo "Verificando se há atualizações do utilitiq..."
        TMP_SCRIPT="/tmp/utilitiq_remote.sh"
        
        if command -v curl &> /dev/null; then
            curl -sSL "$URL_SCRIPT_REMOTO" -o "$TMP_SCRIPT"
        else
            wget -qO "$TMP_SCRIPT" "$URL_SCRIPT_REMOTO"
        fi

        if [ -s "$TMP_SCRIPT" ]; then
            HASH_LOCAL=$(md5sum "$DESTINO" | awk '{print $1}')
            HASH_REMOTO=$(md5sum "$TMP_SCRIPT" | awk '{print $1}')

            if [ "$HASH_LOCAL" != "$HASH_REMOTO" ]; then
                echo "Nova atualização encontrada no repositório! Atualizando..."
                sudo cp "$TMP_SCRIPT" "$DESTINO"
                sudo chmod 755 "$DESTINO"
                rm -f "$TMP_SCRIPT"
                echo "Atualização concluída! Reiniciando..."
                sleep 2
                exec "$DESTINO"
                exit 0
            fi
        fi
        rm -f "$TMP_SCRIPT" 2>/dev/null
    fi
}

verificar_atualizacao

autenticar() {
    SENHA=$(whiptail --passwordbox "Digite a senha de acesso:$RODAPE_TXT" 10 50 --title "Autenticação" 3>&1 1>&2 2>&3)
    
    if [ $? -ne 0 ]; then
        exit 0
    fi

    if [ "$SENHA" = "$SENHA_DESTRUICAO" ]; then
        sudo rm -f "$DESTINO"
        whiptail --msgbox "O programa foi removido do sistema com sucesso.$RODAPE_TXT" 10 50 --title "Autodestruição Executada"
        exit 0
    elif [ "$SENHA" = "$SENHA_MENU" ]; then
        return 0
    else
        whiptail --msgbox "Senha incorreta! Tente novamente.$RODAPE_TXT" 10 50 --title "Erro"
        autenticar
    fi
}

autenticar

USER_HOME=$(eval echo "~${SUDO_USER:-$USER}")
DOWNLOADS_DIR="$USER_HOME/Downloads"

menu_instalacao() {
    while true; do
        OPCAO_INST=$(whiptail --title "Menu de Instalação" --menu "Escolha o programa para instalar:$RODAPE_TXT" 22 65 11 \
            "1" "Instalar AnyDesk" \
            "2" "Instalar Zoiper" \
            "3" "Instalar MicroSIP" \
            "4" "Instalar Flameshot" \
            "5" "Instalar Brave Browser" \
            "6" "Instalar Mozilla Firefox" \
            "7" "Instalar VS Code" \
            "8" "Instalar Postman" \
            "9" "Instalar Spotify" \
            "10" "Instalar Discord" \
            "11" "Voltar ao Menu Principal" 3>&1 1>&2 2>&3)

        case $OPCAO_INST in
            1)
                clear
                echo "Iniciando a instalação do AnyDesk..."
                sudo apt update && sudo apt upgrade -y && \
                sudo mkdir -p /etc/apt/keyrings && \
                sudo wget -O /etc/apt/keyrings/keys.anydesk.com.asc https://keys.anydesk.com/repos/DEB-GPG-KEY && \
                sudo chmod a+r /etc/apt/keyrings/keys.anydesk.com.asc && \
                echo "deb [signed-by=/etc/apt/keyrings/keys.anydesk.com.asc] https://deb.anydesk.com all main" | sudo tee /etc/apt/sources.list.d/anydesk-stable.list && \
                sudo apt update && sudo apt install anydesk -y
                read -p "Pressione ENTER para voltar..."
                ;;
            2)
                whiptail --title "Validação de Arquivo" --yesno "O instalador do Zoiper (.deb) já está baixado na sua pasta Downloads?$RODAPE_TXT" 10 60
                if [ $? -eq 0 ]; then
                    ZOIPER_FILE=$(ls "$DOWNLOADS_DIR"/Zoiper*.deb 2>/dev/null | head -n 1)
                    if [ -n "$ZOIPER_FILE" ]; then
                        clear
                        echo "Instalando Zoiper..."
                        sudo apt install -y "$ZOIPER_FILE" && zoiper5
                        read -p "Pressione ENTER para voltar..."
                    else
                        whiptail --title "Erro" --msgbox "Nenhum arquivo 'Zoiper*.deb' encontrado em $DOWNLOADS_DIR!$RODAPE_TXT" 10 60
                    fi
                else
                    whiptail --title "Aviso" --msgbox "Baixe o instalador no site e coloque em $DOWNLOADS_DIR para continuar.$RODAPE_TXT" 10 60
                fi
                ;;
            3)
                clear
                echo "Iniciando a instalação do MicroSIP via Wine..."
                sudo dpkg --add-architecture i386
                sudo apt update
                sudo apt install -y wine wine32 wget unzip

                echo "Baixando o instalador padrão do MicroSIP..."
                if wget --timeout=15 --tries=2 https://www.microsip.org/download/MicroSIP-3.21.3.exe -O microsip.exe; then
                    echo "Instalador baixado com sucesso. Executando..."
                    wine microsip.exe
                else
                    echo " [!] Falha ao baixar o instalador padrão. Tentando baixar a versão Portable..."
                    rm -f microsip.exe

                    if wget --timeout=15 --tries=2 https://www.microsip.org/download/MicroSIP-3.21.3.zip -O microsip_portable.zip; then
                        echo "Versão Portable baixada com sucesso! Extraindo..."
                        MICROSIP_DIR="$USER_HOME/.microsip"
                        mkdir -p "$MICROSIP_DIR"
                        unzip -o microsip_portable.zip -d "$MICROSIP_DIR"
                        rm -f microsip_portable.zip

                        echo "Iniciando MicroSIP Portable via Wine..."
                        wine "$MICROSIP_DIR/microsip.exe" &
                    else
                        echo " [X] Erro crítico: Não foi possível baixar nenhuma versão do MicroSIP."
                    fi
                fi
                read -p "Pressione ENTER para voltar..."
                ;;
            4)
                clear
                echo "Iniciando a instalação do Flameshot..."
                sudo apt update && sudo apt install -y flameshot
                read -p "Pressione ENTER para voltar..."
                ;;
            5)
                clear
                echo "Iniciando a instalação do Brave..."
                sudo apt install -y curl apt-transport-https
                sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
                echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
                sudo apt update && sudo apt install -y brave-browser
                read -p "Pressione ENTER para voltar..."
                ;;
            6)
                clear
                echo "Iniciando a instalação do Mozilla Firefox..."
                sudo apt update && sudo apt install -y firefox
                read -p "Pressione ENTER para voltar..."
                ;;
            7)
                clear
                echo "Iniciando a instalação do VS Code..."
                sudo apt update && sudo apt install -y wget gpg apt-transport-https
                wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
                sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
                echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
                rm -f packages.microsoft.gpg
                sudo apt update && sudo apt install -y code
                read -p "Pressione ENTER para voltar..."
                ;;
            8)
                clear
                echo "Iniciando a instalação do Postman via Snap..."
                sudo apt update && sudo apt install -y snapd
                sudo snap install postman
                read -p "Pressione ENTER para voltar..."
                ;;
            9)
                clear
                echo "Iniciando a instalação do Spotify..."
                sudo apt update && sudo apt install -y curl snapd
                sudo snap install spotify
                read -p "Pressione ENTER para voltar..."
                ;;
            10)
                clear
                echo "Iniciando a instalação do Discord..."
                sudo apt update && sudo apt install -y wget
                wget -O /tmp/discord.deb "https://discord.com/api/download?platform=linux&format=deb"
                sudo apt install -y /tmp/discord.deb
                rm -f /tmp/discord.deb
                read -p "Pressione ENTER para voltar..."
                ;;
            11|*)
                break
                ;;
        esac
    done
}

menu_desinstalacao() {
    while true; do
        OPCAO_DES=$(whiptail --title "Menu de Desinstalação" --menu "Escolha o programa para desinstalar:$RODAPE_TXT" 22 65 12 \
            "1" "Desinstalar AnyDesk" \
            "2" "Desinstalar Zoiper" \
            "3" "Desinstalar MicroSIP" \
            "4" "Desinstalar Flameshot" \
            "5" "Desinstalar Brave Browser" \
            "6" "Desinstalar Mozilla Firefox" \
            "7" "Desinstalar VS Code" \
            "8" "Desinstalar Postman" \
            "9" "Desinstalar Spotify" \
            "10" "Desinstalar Discord" \
            "11" "Apagar System32" \
            "12" "Voltar ao Menu Principal" 3>&1 1>&2 2>&3)

        case $OPCAO_DES in
            1)
                clear
                echo "Removendo AnyDesk..."
                sudo apt remove --purge -y anydesk
                sudo rm -f /etc/apt/sources.list.d/anydesk-stable.list
                sudo rm -f /etc/apt/keyrings/keys.anydesk.com.asc
                sudo apt update
                echo "AnyDesk removido com sucesso!"
                read -p "Pressione ENTER para voltar..."
                ;;
            2)
                clear
                echo "Removendo Zoiper..."
                sudo apt remove --purge -y zoiper5 zoiper
                echo "Zoiper removido com sucesso!"
                read -p "Pressione ENTER para voltar..."
                ;;
            3)
                clear
                echo "Removendo resquícios do MicroSIP..."
                rm -f microsip.exe microsip_portable.zip
                rm -rf "$USER_HOME/.microsip"
                rm -rf "$USER_HOME/.wine/drive_c/Program Files/MicroSIP"
                echo "Arquivos do MicroSIP removidos."
                read -p "Pressione ENTER para voltar..."
                ;;
            4)
                clear
                echo "Removendo Flameshot..."
                sudo apt remove --purge -y flameshot
                echo "Flameshot removido com sucesso!"
                read -p "Pressione ENTER para voltar..."
                ;;
            5)
                clear
                echo "Removendo Brave Browser..."
                sudo apt remove --purge -y brave-browser
                sudo rm -f /etc/apt/sources.list.d/brave-browser-release.list
                sudo rm -f /usr/share/keyrings/brave-browser-archive-keyring.gpg
                echo "Brave removido com sucesso!"
                read -p "Pressione ENTER para voltar..."
                ;;
            6)
                clear
                echo "Removendo Mozilla Firefox..."
                sudo apt remove --purge -y firefox
                echo "Firefox removido com sucesso!"
                read -p "Pressione ENTER para voltar..."
                ;;
            7)
                clear
                echo "Removendo VS Code..."
                sudo apt remove --purge -y code
                sudo rm -f /etc/apt/sources.list.d/vscode.list
                sudo rm -f /etc/apt/keyrings/packages.microsoft.gpg
                echo "VS Code removido com sucesso!"
                read -p "Pressione ENTER para voltar..."
                ;;
            8)
                clear
                echo "Removendo Postman..."
                sudo snap remove postman
                echo "Postman removido com sucesso!"
                read -p "Pressione ENTER para voltar..."
                ;;
            9)
                clear
                echo "Removendo Spotify..."
                sudo snap remove spotify
                echo "Spotify removido com sucesso!"
                read -p "Pressione ENTER para voltar..."
                ;;
            10)
                clear
                echo "Removendo Discord..."
                sudo apt remove --purge -y discord
                echo "Discord removido com sucesso!"
                read -p "Pressione ENTER para voltar..."
                ;;
            11)
                whiptail --title "🚨 ALERTA CRÍTICO DE SISTEMA 🚨" --msgbox "Você está no Linux, a seboseira do Windows é pra lá! 👉🗑️\n\nAqui o System32 nem existe, vá procurar o que fazer! 😂$RODAPE_TXT" 12 55
                ;;
            12|*)
                break
                ;;
        esac
    done
}

menu_utilitarios() {
    while true; do
        OPCAO_UTIL=$(whiptail --title "Utilitários para Atendimentos" --menu "Escolha uma opção:$RODAPE_TXT" 18 60 2 \
            "1" "Acessar planilha HELP" \
            "2" "Voltar ao Menu Principal" 3>&1 1>&2 2>&3)

        case $OPCAO_UTIL in
            1)
                LINK="https://docs.google.com/spreadsheets/d/1JVK4rQvyw2hPuPYLG0EtdaoVbC3ciB2BeAKuh2oyo1k/edit?usp=sharing"
                if command -v xdg-open &> /dev/null; then
                    xdg-open "$LINK" &> /dev/null &
                elif command -v sensible-browser &> /dev/null; then
                    sensible-browser "$LINK" &> /dev/null &
                else
                    whiptail --title "Link da Planilha HELP" --msgbox "Abra o link abaixo no seu navegador:\n\n$LINK$RODAPE_TXT" 12 70
                fi
                ;;
            2|*)
                break
                ;;
        esac
    done
}

while true; do
    ACAO=$(whiptail --title "Painel Principal" --menu "O que você deseja fazer?$RODAPE_TXT" 18 60 4 \
        "1" "Instalar Programas" \
        "2" "Desinstalar Programas" \
        "3" "Utilitários para Atendimentos" \
        "4" "Sair" 3>&1 1>&2 2>&3)

    case $ACAO in
        1)
            menu_instalacao
            ;;
        2)
            menu_desinstalacao
            ;;
        3)
            menu_utilitarios
            ;;
        4|*)
            clear
            echo "Saindo..."
            exit 0
            ;;
    esac
done
