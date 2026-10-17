#!/bin/bash

# ====================================
# Linux Dev Setup - Herramientas de Hacking para Kali
# ====================================
# Este script instala herramientas de hacking según el perfil seleccionado:
# - all: Todas las herramientas
# - pentesting: Solo herramientas de pentesting
# - network: Solo herramientas de análisis de red
# - web: Solo herramientas de web hacking

set -e

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Obtener perfil desde argumento
HACKING_PROFILE="$1"

if [ -z "$HACKING_PROFILE" ]; then
    print_error "No se especificó perfil de hacking"
    exit 1
fi

print_header "Instalando Herramientas de Hacking"
print_info "Perfil: $HACKING_PROFILE"

# Actualizar repositorios
print_info "Actualizando repositorios..."
sudo apt update

# Instalar herramientas de pentesting
install_pentesting_tools() {
    print_header "Instalando Herramientas de Pentesting"

    pentesting_tools=(
        "nmap"
        "metasploit-framework"
        "nikto"
        "zaproxy"
    )

    for tool in "${pentesting_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1 || dpkg -l | grep -q "$tool"; then
            print_success "$tool ya está instalado"
        else
            print_info "Instalando $tool..."
            sudo apt install -y "$tool"
            print_success "$tool instalado"
        fi
    done

    # Burp Suite (requiere descarga manual o versión community)
    print_info "Burp Suite Community requiere instalación manual desde el sitio web de PortSwigger"
    print_info "Descarga: https://portswigger.net/burp/communitydownload"
}

# Instalar herramientas de análisis de red
install_network_tools() {
    print_header "Instalando Herramientas de Análisis de Red"

    network_tools=(
        "wireshark"
        "tcpdump"
        "netcat"
        "mitmproxy"
    )

    for tool in "${network_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1 || dpkg -l | grep -q "$tool"; then
            print_success "$tool ya está instalado"
        else
            print_info "Instalando $tool..."
            sudo apt install -y "$tool"
            print_success "$tool instalado"
        fi
    done

    # Añadir usuario al grupo wireshark para capturar paquetes
    sudo usermod -aG wireshark $USER
    print_warning "Necesitas cerrar sesión y volver a entrar para usar Wireshark sin sudo"
}

# Instalar herramientas de web hacking
install_web_hacking_tools() {
    print_header "Instalando Herramientas de Web Hacking"

    web_tools=(
        "sqlmap"
        "dirb"
        "gobuster"
        "ffuf"
        "wpscan"
    )

    for tool in "${web_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1 || dpkg -l | grep -q "$tool"; then
            print_success "$tool ya está instalado"
        else
            print_info "Instalando $tool..."
            sudo apt install -y "$tool"
            print_success "$tool instalado"
        fi
    done
}

# Instalar según perfil
case "$HACKING_PROFILE" in
    "all")
        install_pentesting_tools
        install_network_tools
        install_web_hacking_tools
        ;;
    "pentesting")
        install_pentesting_tools
        ;;
    "network")
        install_network_tools
        ;;
    "web")
        install_web_hacking_tools
        ;;
    *)
        print_error "Perfil inválido: $HACKING_PROFILE"
        exit 1
        ;;
esac

print_header "Instalación Completada"
print_success "Herramientas de hacking instaladas"
echo ""
print_info "Herramientas instaladas según perfil: $HACKING_PROFILE"
echo ""
print_warning "Recuerda:"
echo "  - Estas herramientas deben usarse solo para propósitos legítimos"
echo "  - Siempre obtener autorización antes de realizar pruebas"
echo "  - Usa estas herramientas de manera ética y responsable"
