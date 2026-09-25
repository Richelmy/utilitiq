#!/bin/bash

SENHA_MENU_B64="MzEyMzE5"
SENHA_DESTRUICAO_B64="bnVrZQ=="

DESTINO="/usr/local/bin/utilitiq"
RODAPE_TXT=""
URL_SCRIPT_REMOTO="https://raw.githubusercontent.com/Richelmy/utilitiq/main/utilitiq.sh"

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
            HASH_LOCAL=$(md5sum "$DESTINO" 2>/dev/null | awk '{print $1}')
            HASH_REMOTO=$(md5sum "$TMP_SCRIPT" 2>/dev/null | awk '{print $1}')

            if [ -n "$HASH_LOCAL" ] && [ "$HASH_LOCAL" != "$HASH_REMOTO" ]; then
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

autenticar() {
    SENHA=$(whiptail --passwordbox "Digite a senha de acesso:$RODAPE_TXT" 10 50 --title "Autenticação" 3>&1 1>&2 2>&3)
    
    if [ $? -ne 0 ]; then
        exit 0
    fi

    ENTRADA_B64=$(printf "%s" "$SENHA" | base64 2>/dev/null | tr -d '\n\r ')

    if [ "$ENTRADA_B64" = "$SENHA_DESTRUICAO_B64" ]; then
        sudo rm -f "$DESTINO"
        whiptail --msgbox "O programa foi removido do sistema com sucesso.$RODAPE_TXT" 10 50 --title "Autodestruição Executada"
        exit 0
    elif [ "$ENTRADA_B64" = "$SENHA_MENU_B64" ]; then
        return 0
    else
        whiptail --msgbox "Senha incorreta! Tente novamente.$RODAPE_TXT" 10 50 --title "Erro"
        autenticar
    fi
}

autenticar

USER_HOME=$(eval echo "~${SUDO_USER:-$USER}")
REAL_USER="${SUDO_USER:-$USER}"
DOWNLOADS_DIR="$USER_HOME/Downloads"

instalar_anydesk() {
    clear
    echo "Iniciando a instalação do AnyDesk..."
    sudo apt update && sudo apt upgrade -y && \
    sudo mkdir -p /etc/apt/keyrings && \
    sudo wget -O /etc/apt/keyrings/keys.anydesk.com.asc https://keys.anydesk.com/repos/DEB-GPG-KEY && \
    sudo chmod a+r /etc/apt/keyrings/keys.anydesk.com.asc && \
    echo "deb [signed-by=/etc/apt/keyrings/keys.anydesk.com.asc] https://deb.anydesk.com all main" | sudo tee /etc/apt/sources.list.d/anydesk-stable.list && \
    sudo apt update && sudo apt install anydesk -y
}

instalar_zoiper() {
    ZOIPER_FILE=$(ls "$DOWNLOADS_DIR"/Zoiper*.deb 2>/dev/null | head -n 1)
    if [ -n "$ZOIPER_FILE" ]; then
        clear
        echo "Instalando Zoiper..."
        sudo apt install -y "$ZOIPER_FILE"
    else
        whiptail --title "Erro Zoiper" --msgbox "Nenhum arquivo 'Zoiper*.deb' encontrado em $DOWNLOADS_DIR! Baixe o instalador no site e tente novamente.$RODAPE_TXT" 10 60
    fi
}

instalar_microsip() {
    clear
    echo "Iniciando a instalação do MicroSIP via Wine..."
    sudo dpkg --add-architecture i386
    sudo apt update
    sudo apt install -y wine wine32 wget unzip

    echo "Baixando o instalador padrão do MicroSIP..."
    if wget --timeout=15 --tries=2 https://www.microsip.org/download/MicroSIP-3.21.3.exe -O /tmp/microsip.exe; then
        echo "Instalador baixado com sucesso. Executando..."
        wine /tmp/microsip.exe
    else
        echo " [!] Falha ao baixar o instalador padrão. Tentando versão Portable..."
        rm -f /tmp/microsip.exe

        if wget --timeout=15 --tries=2 https://www.microsip.org/download/MicroSIP-3.21.3.zip -O /tmp/microsip_portable.zip; then
            echo "Versão Portable baixada com sucesso! Extraindo..."
            MICROSIP_DIR="$USER_HOME/.microsip"
            mkdir -p "$MICROSIP_DIR"
            unzip -o /tmp/microsip_portable.zip -d "$MICROSIP_DIR"
            rm -f /tmp/microsip_portable.zip

            echo "Iniciando MicroSIP Portable via Wine..."
            wine "$MICROSIP_DIR/microsip.exe" &
        else
            echo " [X] Erro crítico: Não foi possível baixar nenhuma versão do MicroSIP."
        fi
    fi
}

instalar_flameshot() {
    clear
    echo "Iniciando a instalação do Flameshot..."
    sudo apt update && sudo apt install -y flameshot
    
    echo "Definindo Flameshot como atalho padrão de captura de tela (PrtScn)..."
    if [ -n "$REAL_USER" ]; then
        sudo -u "$REAL_USER" gsettings set org.gnome.settings-daemon.plugins.media-keys screenshot '[]' 2>/dev/null
        sudo -u "$REAL_USER" gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Flameshot' 2>/dev/null
        sudo -u "$REAL_USER" gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'flameshot gui' 2>/dev/null
        sudo -u "$REAL_USER" gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding 'Print' 2>/dev/null
        sudo -u "$REAL_USER" gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']" 2>/dev/null
    fi
    echo "Flameshot instalado e configurado como ferramenta padrão!"
}

instalar_brave() {
    clear
    echo "Iniciando a instalação do Brave Browser..."
    sudo apt install -y curl apt-transport-https
    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
    sudo apt update && sudo apt install -y brave-browser
}

instalar_firefox() {
    clear
    echo "Iniciando a instalação do Mozilla Firefox..."
    sudo apt update && sudo apt install -y firefox
}

instalar_tor() {
    clear
    echo "Iniciando a instalação do Tor Browser..."
    sudo apt update && sudo apt install -y torbrowser-launcher
}

instalar_vscode() {
    clear
    echo "Iniciando a instalação do VS Code..."
    sudo apt update && sudo apt install -y wget gpg apt-transport-https
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    rm -f /tmp/packages.microsoft.gpg
    sudo apt update && sudo apt install -y code
}

instalar_postman() {
    clear
    echo "Iniciando a instalação do Postman..."
    sudo apt update && sudo apt install -y snapd
    sudo snap install postman
}

instalar_spotify() {
    clear
    echo "Iniciando a instalação do Spotify..."
    sudo apt update && sudo apt install -y snapd
    sudo snap install spotify
}

instalar_discord() {
    clear
    echo "Iniciando a instalação do Discord..."
    sudo apt update && sudo apt install -y wget
    wget -O /tmp/discord.deb "https://discord.com/api/download?platform=linux&format=deb"
    sudo apt install -y /tmp/discord.deb
    rm -f /tmp/discord.deb
}

instalar_itunes() {
    clear
    echo "Iniciando a instalação do iTunes via Wine..."
    sudo dpkg --add-architecture i386
    sudo apt update && sudo apt install -y wine wine32 wget
    
    echo "Baixando o instalador do iTunes (64-bit)..."
    wget -O /tmp/iTunesSetup.exe "https://www.apple.com/itunes/download/win64"
    if [ -f /tmp/iTunesSetup.exe ]; then
        wine /tmp/iTunesSetup.exe
        rm -f /tmp/iTunesSetup.exe
    else
        echo "[X] Erro ao baixar o iTunes."
    fi
}

instalar_deezer() {
    clear
    echo "Iniciando a instalação do Deezer..."
    sudo apt update && sudo apt install -y snapd
    sudo snap install deezer-desktop || sudo snap install unofficial-deezer
}

instalar_gchat() {
    clear
    echo "Iniciando a criação do atalho do Google Chat..."
    sudo apt update && sudo apt install -y wget
    
    DESKTOP_FILE="/usr/share/applications/google-chat.desktop"
    cat <<EOF | sudo tee "$DESKTOP_FILE" > /dev/null
[Desktop Entry]
Version=1.0
Name=Google Chat
Comment=Google Chat Web App
Exec=xdg-open https://chat.google.com
Icon=web-browser
Terminal=false
Type=Application
Categories=Network;InstantMessaging;
EOF
    echo "Atalho para o Google Chat instalado com sucesso!"
}

menu_padrao_manual() {
    while true; do
        OPCAO_MANUAL=$(whiptail --title "Programas Padrão - Manual" --menu "Escolha o programa para instalar:$RODAPE_TXT" 18 60 5 \
            "1" "AnyDesk" \
            "2" "Zoiper" \
            "3" "MicroSIP" \
            "4" "Flameshot" \
            "5" "Voltar" 3>&1 1>&2 2>&3)

        case $OPCAO_MANUAL in
            1) instalar_anydesk; read -p "Pressione ENTER para voltar..." ;;
            2) instalar_zoiper; read -p "Pressione ENTER para voltar..." ;;
            3) instalar_microsip; read -p "Pressione ENTER para voltar..." ;;
            4) instalar_flameshot; read -p "Pressione ENTER para voltar..." ;;
            5|*) break ;;
        esac
    done
}

menu_programas_padrao() {
    while true; do
        MODO_PADRAO=$(whiptail --title "Programas Padrão" --menu "Como deseja realizar a instalação?$RODAPE_TXT" 18 60 3 \
            "1" "Instalar Tudo de Uma Vez" \
            "2" "Instalar Selecionando Manualmente" \
            "3" "Voltar" 3>&1 1>&2 2>&3)

        case $MODO_PADRAO in
            1)
                whiptail --title "Instalar Tudo" --yesno "Irá instalar em sequência:\n\n- AnyDesk\n- Zoiper (necessita arquivo .deb em Downloads)\n- MicroSIP\n- Flameshot (com atalho configurado)\n\nDeseja continuar?" 14 60
                if [ $? -eq 0 ]; then
                    instalar_anydesk
                    instalar_zoiper
                    instalar_microsip
                    instalar_flameshot
                    whiptail --title "Concluído" --msgbox "Instalação dos programas padrão finalizada!$RODAPE_TXT" 10 50
                fi
                ;;
            2)
                menu_padrao_manual
                ;;
            3|*)
                break
                ;;
        esac
    done
}

menu_navegadores() {
    while true; do
        OPCAO_NAV=$(whiptail --title "Instalar Navegadores" --menu "Escolha o navegador:$RODAPE_TXT" 18 60 4 \
            "1" "Brave Browser" \
            "2" "Mozilla Firefox" \
            "3" "Tor Browser" \
            "4" "Voltar" 3>&1 1>&2 2>&3)

        case $OPCAO_NAV in
            1) instalar_brave; read -p "Pressione ENTER para voltar..." ;;
            2) instalar_firefox; read -p "Pressione ENTER para voltar..." ;;
            3) instalar_tor; read -p "Pressione ENTER para voltar..." ;;
            4|*) break ;;
        esac
    done
}

menu_extras() {
    while true; do
        OPCAO_EXT=$(whiptail --title "Instalar Extras" --menu "Escolha um programa extra:$RODAPE_TXT" 22 60 8 \
            "1" "VS Code" \
            "2" "Postman" \
            "3" "Discord" \
            "4" "Spotify" \
            "5" "iTunes (via Wine)" \
            "6" "Deezer" \
            "7" "Google Chat" \
            "8" "Voltar" 3>&1 1>&2 2>&3)

        case $OPCAO_EXT in
            1) instalar_vscode; read -p "Pressione ENTER para voltar..." ;;
            2) instalar_postman; read -p "Pressione ENTER para voltar..." ;;
            3) instalar_discord; read -p "Pressione ENTER para voltar..." ;;
            4) instalar_spotify; read -p "Pressione ENTER para voltar..." ;;
            5) instalar_itunes; read -p "Pressione ENTER para voltar..." ;;
            6) instalar_deezer; read -p "Pressione ENTER para voltar..." ;;
            7) instalar_gchat; read -p "Pressione ENTER para voltar..." ;;
            8|*) break ;;
        esac
    done
}

menu_instalacao() {
    while true; do
        OPCAO_INST=$(whiptail --title "Menu de Instalação" --menu "Escolha a categoria:$RODAPE_TXT" 18 60 4 \
            "1" "Programas Padrão" \
            "2" "Navegadores" \
            "3" "Extras" \
            "4" "Voltar ao Menu Principal" 3>&1 1>&2 2>&3)

        case $OPCAO_INST in
            1) menu_programas_padrao ;;
            2) menu_navegadores ;;
            3) menu_extras ;;
            4|*) break ;;
        esac
    done
}

menu_desinstalacao() {
    while true; do
        OPCAO_DES=$(whiptail --title "Menu de Desinstalação" --menu "Escolha o programa para desinstalar:$RODAPE_TXT" 24 65 16 \
            "1" "Desinstalar AnyDesk" \
            "2" "Desinstalar Zoiper" \
            "3" "Desinstalar MicroSIP" \
            "4" "Desinstalar Flameshot" \
            "5" "Desinstalar Brave Browser" \
            "6" "Desinstalar Mozilla Firefox" \
            "7" "Desinstalar Tor Browser" \
            "8" "Desinstalar VS Code" \
            "9" "Desinstalar Postman" \
            "10" "Desinstalar Spotify" \
            "11" "Desinstalar Discord" \
            "12" "Desinstalar iTunes" \
            "13" "Desinstalar Deezer" \
            "14" "Desinstalar Google Chat" \
            "15" "Apagar System32" \
            "16" "Voltar ao Menu Principal" 3>&1 1>&2 2>&3)

        case $OPCAO_DES in
            1) clear; sudo apt remove --purge -y anydesk; sudo rm -f /etc/apt/sources.list.d/anydesk-stable.list /etc/apt/keyrings/keys.anydesk.com.asc; sudo apt update; echo "AnyDesk removido!"; read -p "Pressione ENTER para voltar..." ;;
            2) clear; sudo apt remove --purge -y zoiper5 zoiper; echo "Zoiper removido!"; read -p "Pressione ENTER para voltar..." ;;
            3) clear; rm -f /tmp/microsip.exe /tmp/microsip_portable.zip; rm -rf "$USER_HOME/.microsip" "$USER_HOME/.wine/drive_c/Program Files/MicroSIP"; echo "MicroSIP removido!"; read -p "Pressione ENTER para voltar..." ;;
            4) clear; sudo apt remove --purge -y flameshot; echo "Flameshot removido!"; read -p "Pressione ENTER para voltar..." ;;
            5) clear; sudo apt remove --purge -y brave-browser; sudo rm -f /etc/apt/sources.list.d/brave-browser-release.list /usr/share/keyrings/brave-browser-archive-keyring.gpg; echo "Brave removido!"; read -p "Pressione ENTER para voltar..." ;;
            6) clear; sudo apt remove --purge -y firefox; echo "Firefox removido!"; read -p "Pressione ENTER para voltar..." ;;
            7) clear; sudo apt remove --purge -y torbrowser-launcher; rm -rf "$USER_HOME/.local/share/torbrowser"; echo "Tor Browser removido!"; read -p "Pressione ENTER para voltar..." ;;
            8) clear; sudo apt remove --purge -y code; sudo rm -f /etc/apt/sources.list.d/vscode.list /etc/apt/keyrings/packages.microsoft.gpg; echo "VS Code removido!"; read -p "Pressione ENTER para voltar..." ;;
            9) clear; sudo snap remove postman; echo "Postman removido!"; read -p "Pressione ENTER para voltar..." ;;
            10) clear; sudo snap remove spotify; echo "Spotify removido!"; read -p "Pressione ENTER para voltar..." ;;
            11) clear; sudo apt remove --purge -y discord; echo "Discord removido!"; read -p "Pressione ENTER para voltar..." ;;
            12) clear; rm -rf "$USER_HOME/.wine/drive_c/Program Files/iTunes" "$USER_HOME/.wine/drive_c/Program Files (x86)/iTunes"; echo "iTunes removido!"; read -p "Pressione ENTER para voltar..." ;;
            13) clear; sudo snap remove deezer-desktop || sudo snap remove unofficial-deezer; echo "Deezer removido!"; read -p "Pressione ENTER para voltar..." ;;
            14) clear; sudo rm -f /usr/share/applications/google-chat.desktop; echo "Google Chat removido!"; read -p "Pressione ENTER para voltar..." ;;
            15) whiptail --title "🚨 ALERTA CRÍTICO DE SISTEMA 🚨" --msgbox "Você está no Linux, a seboseira do Windows é pra lá! 👉🗑️\n\nAqui o System32 nem existe, vá procurar o que fazer! 😂$RODAPE_TXT" 12 55 ;;
            16|*) break ;;
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
            2|*) break ;;
        esac
    done
}

menu_automacoes() {
    while true; do
        OPCAO_AUTO=$(whiptail --title "Automações" --menu "Escolha uma opção:$RODAPE_TXT" 18 60 2 \
            "1" "Ligar TVs Iqnus" \
            "2" "Voltar ao Menu Principal" 3>&1 1>&2 2>&3)

        case $OPCAO_AUTO in
            1)
                clear
                if ! command -v wakeonlan &> /dev/null; then
                    echo "Instalando dependências necessárias (wakeonlan)..."
                    sudo apt update && sudo apt install -y wakeonlan
                    echo "Dependências instaladas com sucesso!"
                    sleep 1
                fi

                echo "Em processo de ligar as TVs Iqnus..."
                wakeonlan b8:ae:ed:81:d2:be > /dev/null 2>&1 &
                wakeonlan fe80::c7b0:af8d:f1d9:6369 > /dev/null 2>&1 &
                wakeonlan 68:1d:ef:3e:df:6f > /dev/null 2>&1 &
                wakeonlan 68:1d:ef:3e:df:70 > /dev/null 2>&1 &
                wakeonlan 5c:8a:ae:a5:a8:fa > /dev/null 2>&1 &
                wakeonlan fe80::6eed:5a4f:89c0:c271 > /dev/null 2>&1 &
                wakeonlan 68:1d:ef:4f:cb:84 > /dev/null 2>&1 &
                wakeonlan 68:1d:ef:4f:cb:83 > /dev/null 2>&1 &
                wakeonlan 1c:79:2d:be:50:ab > /dev/null 2>&1 &

                sleep 2
                echo "As TVs foram de fato ligadas!"
                whiptail --title "Sucesso" --msgbox "Sinal enviado com sucesso! As TVs foram de fato ligadas.$RODAPE_TXT" 10 50
                read -p "Pressione ENTER para voltar..."
                ;;
            2|*) break ;;
        esac
    done
}

mostrar_creditos() {
    whiptail --title "Créditos" --msgbox "A automação foi feita por mim, Richelmy.\n\nGitHub: github.com/richelmy$RODAPE_TXT" 12 55
}

while true; do
    ACAO=$(whiptail --title "Painel Principal" --menu "O que você deseja fazer?$RODAPE_TXT" 18 60 6 \
        "1" "Instalar Programas" \
        "2" "Desinstalar Programas" \
        "3" "Utilitários para Atendimentos" \
        "4" "Automações" \
        "5" "Créditos" \
        "6" "Sair" 3>&1 1>&2 2>&3)

    case $ACAO in
        1) menu_instalacao ;;
        2) menu_desinstalacao ;;
        3) menu_utilitarios ;;
        4) menu_automacoes ;;
        5) mostrar_creditos ;;
        6|*)
            clear
            echo "Saindo..."
            exit 0
            ;;
    esac
done
