#!/bin/bash

# ====================================
# Linux Dev Setup - Herramientas Base para Kali
# ====================================
# Este script instala las herramientas base de terminal:
# - Zsh, Oh My Zsh, Starship
# - Tree, Bat, Btop
# - LazyGit, Yazi
# - Ripgrep, fd-find

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

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_header "Instalando Herramientas Base"

# Actualizar repositorios
print_info "Actualizando repositorios..."
sudo apt update

# Instalar dependencias
print_info "Instalando dependencias básicas..."
sudo apt install -y curl wget git unzip build-essential

# Instalar herramientas base
tools=(
    "zsh"
    "tree"
    "bat"
    "btop"
    "ripgrep"
    "fd-find"
)

for tool in "${tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        print_success "$tool ya está instalado"
    else
        print_info "Instalando $tool..."
        case "$tool" in
            "bat")
                sudo apt install -y bat
                if [ ! -L /usr/local/bin/bat ]; then
                    sudo ln -s /usr/bin/batcat /usr/local/bin/bat
                fi
                ;;
            "fd-find")
                sudo apt install -y fd-find
                if [ ! -L /usr/local/bin/fd ]; then
                    sudo ln -s /usr/bin/fdfind /usr/local/bin/fd
                fi
                ;;
            *)
                sudo apt install -y "$tool"
                ;;
        esac
        print_success "$tool instalado"
    fi
done

# Instalar Oh My Zsh
print_header "Instalando Oh My Zsh"
if [ -d "$HOME/.oh-my-zsh" ]; then
    print_success "Oh My Zsh ya está instalado"
else
    print_info "Instalando Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    print_success "Oh My Zsh instalado"
fi

# Instalar Starship
print_header "Instalando Starship"
if command -v starship >/dev/null 2>&1; then
    print_success "Starship ya está instalado"
else
    print_info "Instalando Starship..."
    curl -fsSL https://starship.rs/install.sh | sh
    print_success "Starship instalado"
fi

# Instalar LazyGit
print_header "Instalando LazyGit"
if command -v lazygit >/dev/null 2>&1; then
    print_success "LazyGit ya está instalado"
else
    print_info "Instalando LazyGit..."
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz
    sudo install lazygit /usr/local/bin
    rm lazygit.tar.gz lazygit
    print_success "LazyGit instalado"
fi

# Instalar Yazi
print_header "Instalando Yazi"
if command -v yazi >/dev/null 2>&1; then
    print_success "Yazi ya está instalado"
else
    print_info "Instalando Yazi..."
    sudo apt install -y unzip

    if command -v cargo >/dev/null 2>&1; then
        cargo install --locked yazi
    else
        print_info "Instalando Rust primero..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
        cargo install --locked yazi
    fi
    print_success "Yazi instalado"
fi

# Configurar Zsh
print_header "Configurando Zsh"
if [ "$SHELL" != "/bin/zsh" ]; then
    print_info "Cambiando shell por defecto a zsh..."
    chsh -s $(which zsh)
    print_success "Shell cambiado a zsh"
else
    print_success "Zsh ya es el shell por defecto"
fi

# Añadir Starship a .zshrc
if ! grep -q "starship init zsh" "$HOME/.zshrc"; then
    print_info "Añadiendo Starship a .zshrc..."
    echo 'eval "$(starship init zsh)"' >> "$HOME/.zshrc"
    print_success "Starship configurado"
else
    print_success "Starship ya está configurado"
fi

print_header "Instalación Completada"
print_success "Herramientas base instaladas"
echo ""
print_info "Pasos siguientes:"
echo "  1. Cierra sesión y vuelve a entrar"
echo "  2. Ejecuta 'exec zsh' para iniciar Zsh"
