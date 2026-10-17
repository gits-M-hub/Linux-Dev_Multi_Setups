#!/bin/bash

# ====================================
# Linux Dev Setup - Script Principal para Kali Linux
# ====================================
# Este script automatiza la instalación del entorno de desarrollo
# para Kali Linux con herramientas de hacking.

set -e

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funciones de utilidad
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

# Verificar si se ejecuta como root
check_sudo() {
    if [ "$EUID" -eq 0 ]; then
        print_error "No ejecutes este script como root. Ejecútalo como usuario normal."
        exit 1
    fi
}

# Verificar sistema operativo
check_os() {
    if [ ! -f /etc/os-release ]; then
        print_error "No se pudo detectar el sistema operativo."
        exit 1
    fi

    source /etc/os-release
    if [[ "$ID" != "kali" ]]; then
        print_warning "Este script está diseñado para Kali Linux. Puede funcionar en otros sistemas, pero no está garantizado."
        read -p "¿Continuar? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Seleccionar perfil de herramientas de hacking
select_hacking_profile() {
    print_header "Seleccionar Perfil de Herramientas de Hacking"

    echo "Seleccione el perfil de herramientas de hacking a instalar:"
    echo ""
    echo "1) Todas las herramientas (Pentesting + Red + Web)"
    echo "2) Solo Pentesting (Nmap, Metasploit, Burp Suite, Nikto, OWASP ZAP)"
    echo "3) Solo Análisis de Red (Wireshark, tcpdump, netcat, mitmproxy)"
    echo "4) Solo Web Hacking (sqlmap, dirb, gobuster, ffuf, wpscan)"
    echo ""
    read -p "Opción (1-4): " profile_choice

    case "$profile_choice" in
        1)
            HACKING_PROFILE="all"
            print_success "Perfil seleccionado: Todas las herramientas"
            ;;
        2)
            HACKING_PROFILE="pentesting"
            print_success "Perfil seleccionado: Pentesting"
            ;;
        3)
            HACKING_PROFILE="network"
            print_success "Perfil seleccionado: Análisis de Red"
            ;;
        4)
            HACKING_PROFILE="web"
            print_success "Perfil seleccionado: Web Hacking"
            ;;
        *)
            print_error "Opción inválida"
            exit 1
            ;;
    esac
}

# Función principal
main() {
    print_header "Linux Dev Setup - Instalación para Kali Linux"

    check_sudo
    check_os
    select_hacking_profile

    print_info "Este script instalará:"
    echo "  - Herramientas base (Zsh, Tree, Bat, Btop, etc.)"
    echo "  - Oh My Zsh y Starship"
    echo "  - LazyGit y Yazi"
    echo "  - Docker"
    echo "  - VS Code"
    echo "  - GCC"
    echo "  - Herramientas de hacking ($HACKING_PROFILE)"
    echo "  - Configuraciones de Zsh, Starship y Git"
    echo ""
    print_warning "NOTA: No se instalará Java/Kotlin/SDKMAN ni PostgreSQL (no necesarios para hacking)"
    echo ""

    read -p "¿Continuar? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Instalación cancelada"
        exit 1
    fi

    echo ""

    # Ejecutar scripts de instalación
    print_header "Iniciando Instalación"

    # Script de instalación base
    bash "$HOME/Projects/linux-dev-setup/scripts/install/kali/install-base-tools.sh"

    # Script de instalación de herramientas de desarrollo
    bash "$HOME/Projects/linux-dev-setup/scripts/install/kali/install-dev-tools.sh"

    # Script de instalación de herramientas de hacking
    bash "$HOME/Projects/linux-dev-setup/scripts/install/kali/install-hacking-tools.sh" "$HACKING_PROFILE"

    print_header "Instalación Completada"

    print_success "Todas las herramientas han sido instaladas"
    echo ""
    print_info "Pasos siguientes:"
    echo "  1. Cierra sesión y vuelve a entrar para aplicar los cambios"
    echo "  2. Ejecuta 'exec zsh' para iniciar Zsh"
    echo "  3. Revisa la documentación en docs/ para más información"
    echo ""
    print_warning "Docker requiere que cierres sesión y vuelvas a entrar para usarlo sin sudo"
}

# Ejecutar función principal
main
