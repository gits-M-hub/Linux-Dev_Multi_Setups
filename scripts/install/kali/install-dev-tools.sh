#!/bin/bash

# ====================================
# Linux Dev Setup - Herramientas de Desarrollo para Kali
# ====================================
# Este script instala herramientas de desarrollo para Kali Linux:
# - Docker
# - VS Code
# - GCC
# - Git (ya viene en Kali, pero configuramos)
# - Configuraciones de Git

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

print_header "Instalando Herramientas de Desarrollo"

# Instalar GCC
print_header "Instalando GCC"
if command -v gcc >/dev/null 2>&1; then
    print_success "GCC ya está instalado"
else
    print_info "Instalando GCC..."
    sudo apt install -y gcc g++ make
    print_success "GCC instalado"
fi

# Instalar Docker
print_header "Instalando Docker"
if command -v docker >/dev/null 2>&1; then
    print_success "Docker ya está instalado"
else
    print_info "Instalando Docker..."
    print_warning "Kali usa el repositorio de Docker para Debian bookworm"

    # Añadir repositorio de Docker (usando bookworm ya que kali-rolling no está soportado)
    sudo apt-get install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      bookworm stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Añadir usuario al grupo docker
    sudo usermod -aG docker $USER

    print_success "Docker instalado"
    print_warning "Necesitas cerrar sesión y volver a entrar para que el grupo docker surta efecto"
fi

# Instalar VS Code
print_header "Instalando VS Code"
if command -v code >/dev/null 2>&1; then
    print_success "VS Code ya está instalado"
else
    print_info "Instalando VS Code..."

    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -f packages.microsoft.gpg

    sudo apt update
    sudo apt install -y code

    print_success "VS Code instalado"
fi

# Configurar Git
print_header "Configurando Git"

# Solicitar nombre y email
if [ -z "$(git config --global user.name)" ]; then
    read -p "Ingresa tu nombre para Git: " git_name
    git config --global user.name "$git_name"
fi

if [ -z "$(git config --global user.email)" ]; then
    read -p "Ingresa tu email para Git: " git_email
    git config --global user.email "$git_email"
fi

# Configurar defaults
git config --global init.defaultBranch main
git config --global core.autocrlf input

print_success "Git configurado"

# Instalar alias
print_header "Instalando Alias"
if [ -f "$HOME/Projects/linux-dev-setup/scripts/install/install-aliases.sh" ]; then
    bash "$HOME/Projects/linux-dev-setup/scripts/install/install-aliases.sh"
    print_success "Alias instalados"
else
    print_warning "Script de alias no encontrado, saltando..."
fi

print_header "Instalación Completada"
print_success "Herramientas de desarrollo instaladas"
echo ""
print_info "Herramientas instaladas:"
echo "  - GCC (compilador C/C++)"
echo "  - Docker"
echo "  - VS Code"
echo "  - Git (configurado)"
echo ""
print_warning "NOTA: No se instalaron Java/Kotlin/SDKMAN ni PostgreSQL (no necesarios para hacking)"
