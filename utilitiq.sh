#!/bin/bash

# --- DANGER ZONE | CUIDADO AMIGUE ISSO AQUI QUEIMA ---
SENHA_MENU="312319"
SENHA_DESTRUICAO="nuke"
DESTINO="/usr/local/bin/utilitiq"

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
    SENHA=$(whiptail --passwordbox "Digite a senha de acesso:" 8 45 --title "Autenticação" 3>&1 1>&2 2>&3)
    
    if [ $? -ne 0 ]; then
        exit 0
    fi

    if [ "$SENHA" = "$SENHA_DESTRUICAO" ]; then
        sudo rm -f "$DESTINO"
        whiptail --msgbox "O programa foi removido do sistema com sucesso." 8 50 --title "Autodestruição Executada"
        exit 0
    elif [ "$SENHA" = "$SENHA_MENU" ]; then
        return 0
    else
        whiptail --msgbox "Senha incorreta! Tente novamente." 8 45 --title "Erro"
        autenticar
    fi
}

autenticar

USER_HOME=$(eval echo "~${SUDO_USER:-$USER}")
DOWNLOADS_DIR="$USER_HOME/Downloads"

# --- SUBMENU: INSTALAÇÃO ---
menu_instalacao() {
    while true; do
        OPCAO_INST=$(whiptail --title "Menu de Instalação" --menu "Escolha o programa para instalar:" 18 60 5 \
            "1" "Instalar AnyDesk" \
            "2" "Instalar Zoiper" \
            "3" "Instalar MicroSIP" \
            "4" "Instalar Flameshot" \
            "5" "Voltar ao Menu Principal" 3>&1 1>&2 2>&3)

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
                whiptail --title "Validação de Arquivo" --yesno "O instalador do Zoiper (.deb) já está baixado na sua pasta Downloads?" 8 60
                if [ $? -eq 0 ]; then
                    ZOIPER_FILE=$(ls "$DOWNLOADS_DIR"/Zoiper*.deb 2>/dev/null | head -n 1)
                    if [ -n "$ZOIPER_FILE" ]; then
                        clear
                        echo "Instalando Zoiper..."
                        sudo apt install -y "$ZOIPER_FILE" && zoiper5
                        read -p "Pressione ENTER para voltar..."
                    else
                        whiptail --title "Erro" --msgbox "Nenhum arquivo 'Zoiper*.deb' encontrado em $DOWNLOADS_DIR!" 10 60
                    fi
                else
                    whiptail --title "Aviso" --msgbox "Baixe o instalador no site e coloque em $DOWNLOADS_DIR para continuar." 9 60
                fi
                ;;
            3)
                clear
                echo "Iniciando a instalação do MicroSIP via Wine..."
                sudo apt update
                sudo apt install -y wine wget
                wget https://www.microsip.org/download/MicroSIP-3.21.3.exe -O microsip.exe
                wine microsip.exe
                read -p "Pressione ENTER para voltar..."
                ;;
            4)
                clear
                echo "Iniciando a instalação do Flameshot..."
                sudo apt update && sudo apt install -y flameshot
                read -p "Pressione ENTER para voltar..."
                ;;
            5|*)
                break
                ;;
        esac
    done
}

# --- SUBMENU: DESINSTALAÇÃO ---
menu_desinstalacao() {
    while true; do
        OPCAO_DES=$(whiptail --title "Menu de Desinstalação" --menu "Escolha o programa para desinstalar:" 18 60 6 \
            "1" "Desinstalar AnyDesk" \
            "2" "Desinstalar Zoiper" \
            "3" "Desinstalar MicroSIP" \
            "4" "Desinstalar Flameshot" \
            "5" "Apagar System32" \
            "6" "Voltar ao Menu Principal" 3>&1 1>&2 2>&3)

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
                rm -f microsip.exe
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
                whiptail --title "🚨 ALERTA CRÍTICO DE SISTEMA 🚨" --msgbox "Você está no Linux, a seboseira do Windows é pra lá! 👉🗑️\n\nAqui o System32 nem existe, vá procurar o que fazer! 😂" 11 55
                ;;
            6|*)
                break
                ;;
        esac
    done
}

# --- MENU PRINCIPAL (SELECIONADOR) ---
while true; do
    ACAO=$(whiptail --title "Painel Principal" --menu "O que você deseja fazer?" 15 60 3 \
        "1" "Instalar Programas" \
        "2" "Desinstalar Programas" \
        "3" "Sair" 3>&1 1>&2 2>&3)

    case $ACAO in
        1)
            menu_instalacao
            ;;
        2)
            menu_desinstalacao
            ;;
        3|*)
            clear
            echo "Saindo..."
            exit 0
            ;;
    esac
done
