#!/bin/bash

# ====================================
# Linux Dev Setup - Script Principal (Arch Linux)
# ====================================
# Este script automatiza la instalación completa del entorno de desarrollo
# para Arch Linux, incluyendo herramientas base, desarrollo y configuraciones.

set -e

# Obtener la ruta del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../" && pwd)"

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
    if [[ "$ID" != "arch" && "$ID" != "manjaro" ]]; then
        print_warning "Este script está diseñado para Arch Linux/Manjaro. Puede funcionar en otros sistemas, pero no está garantizado."
        read -p "¿Continuar? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Actualizar sistema
update_system() {
    print_header "Actualizando sistema"
    
    print_info "Actualizando repositorios..."
    sudo pacman -Syu --noconfirm
    
    print_info "Instalando dependencias básicas..."
    sudo pacman -S --noconfirm --needed base-devel curl wget git unzip
    
    print_success "Sistema actualizado"
}

# Instalar herramientas base
install_base_tools() {
    print_header "Instalando herramientas base"
    
    local tools=(
        "zsh"
        "tree"
        "bat"
        "btop"
        "ripgrep"
        "fd"
    )
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            print_success "$tool ya está instalado"
        else
            print_info "Instalando $tool..."
            sudo pacman -S --noconfirm "$tool"
            print_success "$tool instalado"
        fi
    done
}

# Instalar Oh My Zsh
install_oh_my_zsh() {
    print_header "Instalando Oh My Zsh"
    
    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_success "Oh My Zsh ya está instalado"
    else
        print_info "Instalando Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        print_success "Oh My Zsh instalado"
    fi
}

# Instalar Starship
install_starship() {
    print_header "Instalando Starship"
    
    if command -v starship >/dev/null 2>&1; then
        print_success "Starship ya está instalado"
    else
        print_info "Instalando Starship..."
        curl -fsSL https://starship.rs/install.sh | sh
        print_success "Starship instalado"
    fi
}

# Instalar LazyGit
install_lazygit() {
    print_header "Instalando LazyGit"
    
    if command -v lazygit >/dev/null 2>&1; then
        print_success "LazyGit ya está instalado"
    else
        print_info "Instalando LazyGit desde AUR..."
        
        # Instalar yay si no está
        if ! command -v yay >/dev/null 2>&1; then
            print_info "Instalando yay (AUR helper)..."
            sudo pacman -S --noconfirm --needed base-devel
            git clone https://aur.archlinux.org/yay.git /tmp/yay
            cd /tmp/yay
            makepkg -si --noconfirm
            cd -
            rm -rf /tmp/yay
        fi
        
        yay -S --noconfirm lazygit
        print_success "LazyGit instalado"
    fi
}

# Instalar Yazi
install_yazi() {
    print_header "Instalando Yazi"
    
    if command -v yazi >/dev/null 2>&1; then
        print_success "Yazi ya está instalado"
    else
        print_info "Instalando Yazi desde AUR..."
        
        if ! command -v yay >/dev/null 2>&1; then
            print_info "Instalando yay (AUR helper)..."
            sudo pacman -S --noconfirm --needed base-devel
            git clone https://aur.archlinux.org/yay.git /tmp/yay
            cd /tmp/yay
            makepkg -si --noconfirm
            cd -
            rm -rf /tmp/yay
        fi
        
        yay -S --noconfirm yazi
        print_success "Yazi instalado"
    fi
}

# Instalar SDKMAN
install_sdkman() {
    print_header "Instalando SDKMAN!"
    
    if [ -d "$HOME/.sdkman" ]; then
        print_success "SDKMAN! ya está instalado"
    else
        print_info "Instalando SDKMAN!..."
        curl -s "https://get.sdkman.io" | bash
        source "$HOME/.sdkman/bin/sdkman-init.sh"
        print_success "SDKMAN! instalado"
    fi
}

# Instalar Java
install_java() {
    print_header "Instalando Java"
    
    if [ ! -d "$HOME/.sdkman" ]; then
        print_error "SDKMAN! no está instalado. Instalando primero..."
        install_sdkman
    fi
    
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    
    if sdk list java | grep -q "installed"; then
        print_success "Java ya está instalado"
        sdk list java | grep "installed"
    else
        print_info "Instalando Java 21 LTS..."
        sdk install java 21.0.1-tem
        print_success "Java instalado"
    fi
}

# Instalar Kotlin
install_kotlin() {
    print_header "Instalando Kotlin"
    
    if [ ! -d "$HOME/.sdkman" ]; then
        print_error "SDKMAN! no está instalado. Instalando primero..."
        install_sdkman
    fi
    
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    
    if sdk list kotlin | grep -q "installed"; then
        print_success "Kotlin ya está instalado"
        sdk list kotlin | grep "installed"
    else
        print_info "Instalando Kotlin..."
        sdk install kotlin
        print_success "Kotlin instalado"
    fi
}

# Instalar Docker
install_docker() {
    print_header "Instalando Docker"
    
    if command -v docker >/dev/null 2>&1; then
        print_success "Docker ya está instalado"
    else
        print_info "Instalando Docker..."
        sudo pacman -S --noconfirm docker docker-compose
        
        # Habilitar e iniciar Docker
        sudo systemctl enable docker
        sudo systemctl start docker
        
        # Añadir usuario al grupo docker
        sudo usermod -aG docker $USER
        
        print_success "Docker instalado"
        print_warning "Necesitas cerrar sesión y volver a entrar para que el grupo docker surta efecto"
    fi
}

# Instalar VS Code
install_vscode() {
    print_header "Instalando VS Code"
    
    if command -v code >/dev/null 2>&1; then
        print_success "VS Code ya está instalado"
    else
        print_info "Instalando VS Code desde AUR..."
        
        if ! command -v yay >/dev/null 2>&1; then
            print_info "Instalando yay (AUR helper)..."
            sudo pacman -S --noconfirm --needed base-devel
            git clone https://aur.archlinux.org/yay.git /tmp/yay
            cd /tmp/yay
            makepkg -si --noconfirm
            cd -
            rm -rf /tmp/yay
        fi
        
        yay -S --noconfirm visual-studio-code-bin
        print_success "VS Code instalado"
    fi
}

# Instalar PostgreSQL
install_postgresql() {
    print_header "Instalando PostgreSQL"
    
    if command -v psql >/dev/null 2>&1; then
        print_success "PostgreSQL ya está instalado"
    else
        print_info "Instalando PostgreSQL..."
        sudo pacman -S --noconfirm postgresql
        
        # Inicializar base de datos
        sudo -u postgres initdb -D /var/lib/postgres/data
        
        # Habilitar e iniciar PostgreSQL
        sudo systemctl enable postgresql
        sudo systemctl start postgresql
        
        print_success "PostgreSQL instalado"
    fi
}

# Configurar Zsh
configure_zsh() {
    print_header "Configurando Zsh"
    
    # Cambiar shell por defecto a zsh
    if [ "$SHELL" != "/bin/zsh" ]; then
        print_info "Cambiando shell por defecto a zsh..."
        chsh -s $(which zsh)
        print_success "Shell cambiado a zsh"
    else
        print_success "Zsh ya es el shell por defecto"
    fi
    
    # Instalar alias
    print_info "Instalando alias..."
    "$PROJECT_ROOT/scripts/install/install-aliases.sh"
}

# Configurar Starship
configure_starship() {
    print_header "Configurando Starship"
    
    # Añadir starship al .zshrc si no está
    if ! grep -q "starship init zsh" "$HOME/.zshrc"; then
        print_info "Añadiendo Starship a .zshrc..."
        echo 'eval "$(starship init zsh)"' >> "$HOME/.zshrc"
        print_success "Starship configurado"
    else
        print_success "Starship ya está configurado"
    fi
    
    # Copiar configuración de starship si existe
    if [ -f "$PROJECT_ROOT/configs/starship/starship.toml" ]; then
        print_info "Copiando configuración de Starship..."
        mkdir -p "$HOME/.config"
        cp "$PROJECT_ROOT/configs/starship/starship.toml" "$HOME/.config/starship.toml"
        print_success "Configuración de Starship copiada"
    fi
}

# Configurar Git
configure_git() {
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
}

# Función principal
main() {
    print_header "Linux Dev Setup - Instalación (Arch Linux)"
    
    check_sudo
    check_os
    
    print_info "Este script instalará:"
    echo "  - Herramientas base (Zsh, Tree, Bat, Btop, etc.)"
    echo "  - Oh My Zsh y Starship"
    echo "  - LazyGit y Yazi"
    echo "  - SDKMAN!, Java y Kotlin"
    echo "  - Docker"
    echo "  - VS Code"
    echo "  - PostgreSQL"
    echo "  - Configuraciones de Zsh, Starship y Git"
    echo ""
    
    read -p "¿Continuar? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Instalación cancelada"
        exit 1
    fi
    
    echo ""
    
    # Ejecutar instalación
    update_system
    install_base_tools
    install_oh_my_zsh
    install_starship
    install_lazygit
    install_yazi
    install_sdkman
    install_java
    install_kotlin
    install_docker
    install_vscode
    install_postgresql
    configure_zsh
    configure_starship
    configure_git
    
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
