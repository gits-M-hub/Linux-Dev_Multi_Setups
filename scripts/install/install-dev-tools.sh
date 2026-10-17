#!/bin/bash

# ====================================
# Linux Dev Setup - Herramientas de Desarrollo
# ====================================
# Este script instala las herramientas de desarrollo:
# - SDKMAN!, Java, Kotlin
# - Docker
# - VS Code
# - PostgreSQL

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

print_header "Instalando Herramientas de Desarrollo"

# Instalar SDKMAN
print_header "Instalando SDKMAN!"
if [ -d "$HOME/.sdkman" ]; then
    print_success "SDKMAN! ya está instalado"
else
    print_info "Instalando SDKMAN!..."
    curl -s "https://get.sdkman.io" | bash
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    print_success "SDKMAN! instalado"
fi

# Instalar Java
print_header "Instalando Java"
if [ ! -d "$HOME/.sdkman" ]; then
    print_error "SDKMAN! no está instalado"
    exit 1
fi

source "$HOME/.sdkman/bin/sdkman-init.sh"

if sdk list java 2>/dev/null | grep -q "installed"; then
    print_success "Java ya está instalado"
    sdk list java | grep "installed"
else
    print_info "Instalando Java 21 LTS..."
    sdk install java 21.0.1-tem
    print_success "Java instalado"
fi

# Instalar Kotlin
print_header "Instalando Kotlin"
if sdk list kotlin 2>/dev/null | grep -q "installed"; then
    print_success "Kotlin ya está instalado"
    sdk list kotlin | grep "installed"
else
    print_info "Instalando Kotlin..."
    sdk install kotlin
    print_success "Kotlin instalado"
fi

# Instalar Gradle
print_header "Instalando Gradle"
if sdk list gradle 2>/dev/null | grep -q "installed"; then
    print_success "Gradle ya está instalado"
    sdk list gradle | grep "installed"
else
    print_info "Instalando Gradle..."
    sdk install gradle
    print_success "Gradle instalado"
fi

# Instalar Docker
print_header "Instalando Docker"
if command -v docker >/dev/null 2>&1; then
    print_success "Docker ya está instalado"
else
    print_info "Instalando Docker..."
    
    # Añadir repositorio de Docker
    sudo apt-get install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
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

# Instalar PostgreSQL
print_header "Instalando PostgreSQL"
if command -v psql >/dev/null 2>&1; then
    print_success "PostgreSQL ya está instalado"
else
    print_info "Instalando PostgreSQL..."
    sudo apt install -y postgresql postgresql-contrib
    print_success "PostgreSQL instalado"
fi

# Configurar Git
print_header "Configurando Git"
if [ -z "$(git config --global user.name)" ]; then
    read -p "Ingresa tu nombre para Git: " git_name
    git config --global user.name "$git_name"
fi

if [ -z "$(git config --global user.email)" ]; then
    read -p "Ingresa tu email para Git: " git_email
    git config --global user.email "$git_email"
fi

git config --global init.defaultBranch main
git config --global core.autocrlf input

print_success "Git configurado"

# Instalar alias
print_header "Instalando Alias"
if [ -f "$PROJECT_ROOT/scripts/install/install-aliases.sh" ]; then
    print_info "Ejecutando script de instalación de alias..."
    "$PROJECT_ROOT/scripts/install/install-aliases.sh"
    print_success "Alias instalados"
else
    print_warning "Script de instalación de alias no encontrado en $PROJECT_ROOT"
fi

print_header "Instalación Completada"
print_success "Herramientas de desarrollo instaladas"
echo ""
print_info "Herramientas instaladas:"
echo "  - SDKMAN!, Java 21, Kotlin, Gradle"
echo "  - Docker y Docker Compose"
echo "  - VS Code"
echo "  - PostgreSQL"
echo "  - Git configurado"
echo ""
print_warning "Docker requiere que cierres sesión y vuelvas a entrar para usarlo sin sudo"
print_info "Revisa docs/postgresql/ para configuración de PostgreSQL"
