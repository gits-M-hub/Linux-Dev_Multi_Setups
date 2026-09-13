#!/bin/bash

# ====================================
# Linux Dev Setup - Herramientas de Desarrollo (Fedora)
# ====================================
# Este script instala las herramientas de desarrollo:
# - SDKMAN!, Java, Kotlin
# - Docker
# - VS Code
# - PostgreSQL

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

print_header "Instalando Herramientas de Desarrollo (Fedora)"

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
    
    sudo dnf -y install dnf-plugins-core
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    
    print_info "Instalando paquetes de Docker..."
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    print_info "Habilitando e iniciando servicio Docker..."
    sudo systemctl enable docker
    sudo systemctl start docker
    
    # Verificar que Docker está corriendo
    if sudo systemctl is-active --quiet docker; then
        print_success "Docker está corriendo correctamente"
    else
        print_error "Docker no se pudo iniciar correctamente"
        print_info "Verifica con: sudo systemctl status docker"
        exit 1
    fi
    
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
    
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    
    sudo dnf install -y code
    
    print_success "VS Code instalado"
fi

# Instalar PostgreSQL
print_header "Instalando PostgreSQL"
if command -v psql >/dev/null 2>&1; then
    print_success "PostgreSQL ya está instalado"
else
    print_info "Instalando PostgreSQL..."
    sudo dnf install -y postgresql postgresql-server
    
    print_info "Inicializando base de datos..."
    sudo /usr/bin/postgresql-setup --initdb
    
    print_info "Habilitando e iniciando servicio PostgreSQL..."
    sudo systemctl enable postgresql
    sudo systemctl start postgresql
    
    # Verificar que PostgreSQL está corriendo
    if sudo systemctl is-active --quiet postgresql; then
        print_success "PostgreSQL está corriendo correctamente"
    else
        print_error "PostgreSQL no se pudo iniciar correctamente"
        print_info "Verifica con: sudo systemctl status postgresql"
        exit 1
    fi
    
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
if [ -f "$HOME/Projects/linux-dev-setup/scripts/install/install-aliases.sh" ]; then
    print_info "Ejecutando script de instalación de alias (Fedora)..."
    "$HOME/Projects/linux-dev-setup/scripts/install/install-aliases.sh" --fedora
    print_success "Alias instalados"
else
    print_warning "Script de instalación de alias no encontrado en $HOME/Projects/linux-dev-setup"
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
