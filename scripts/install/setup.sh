#!/bin/bash

# ====================================
# Linux Dev Setup - Script Principal (Multi-Distro)
# ====================================
# Este script detecta la distribución de Linux y ejecuta el script
# de instalación correspondiente.

set -e

# Obtener la ruta del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

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

# Detectar distribución de Linux
detect_distro() {
    if [ ! -f /etc/os-release ]; then
        print_error "No se pudo detectar el sistema operativo."
        exit 1
    fi

    source /etc/os-release
    
    case "$ID" in
        ubuntu|pop|linuxmint|kubuntu|xubuntu|debian)
            DISTRO_FAMILY="debian"
            DISTRO_NAME="$NAME"
            ;;
        kali)
            DISTRO_FAMILY="kali"
            DISTRO_NAME="$NAME"
            ;;
        arch|manjaro)
            DISTRO_FAMILY="arch"
            DISTRO_NAME="$NAME"
            ;;
        fedora|rhel|centos)
            DISTRO_FAMILY="fedora"
            DISTRO_NAME="$NAME"
            ;;
        *)
            DISTRO_FAMILY="unknown"
            DISTRO_NAME="$NAME"
            ;;
    esac
}

# Función principal
main() {
    print_header "Linux Dev Setup - Instalación Multi-Distro"
    
    detect_distro
    
    print_info "Distribución detectada: $DISTRO_NAME"
    print_info "Familia: $DISTRO_FAMILY"
    echo ""
    
    case "$DISTRO_FAMILY" in
        debian)
            print_success "Ejecutando script para Debian/Ubuntu/Pop!_OS..."
            bash "$PROJECT_ROOT/scripts/install/debian/setup.sh"
            ;;
        kali)
            print_success "Ejecutando script para Kali Linux..."
            bash "$PROJECT_ROOT/scripts/install/kali/setup.sh"
            ;;
        arch)
            print_success "Ejecutando script para Arch Linux/Manjaro..."
            bash "$PROJECT_ROOT/scripts/install/arch/setup.sh"
            ;;
        fedora)
            print_success "Ejecutando script para Fedora/RHEL/CentOS..."
            bash "$PROJECT_ROOT/scripts/install/fedora/setup.sh"
            ;;
        *)
            print_error "Distribución no soportada: $DISTRO_NAME"
            print_info "Distribuciones soportadas:"
            echo "  - Ubuntu, Pop!_OS, Linux Mint, Debian"
            echo "  - Kali Linux"
            echo "  - Arch Linux, Manjaro"
            echo "  - Fedora, RHEL, CentOS"
            exit 1
            ;;
    esac
}

# Ejecutar función principal
main
