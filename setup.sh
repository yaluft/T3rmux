#!/usr/bin/env bash

# Termux Ultimate Setup Script
# Repository Setup, Development Tools, Modern CLI Replacements & Customization

# Color definitions for installer output
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}        Termux Development & CLI Setup              ${NC}"
echo -e "${CYAN}====================================================${NC}\n"

# 1. Update system & repos
echo -e "${CYAN}[1/6] Updating Termux package repositories...${NC}"
pkg update -y && pkg upgrade -y

# 2. Grant Storage Access
echo -e "${CYAN}[2/6] Requesting Android storage permissions...${NC}"
termux-setup-storage || true

# 3. Enable extra repositories for btop & other tools
echo -e "${CYAN}[3/6] Enabling TUR and X11 repositories...${NC}"
pkg install -y tur-repo x11-repo || true
pkg update -y

# 4. Install Packages
echo -e "${CYAN}[4/6] Installing Development & Modern CLI Packages...${NC}"
PACKAGES=(
  git
  python
  nodejs-lts
  clang
  make
  ninja
  pkg-config
  curl
  wget
  nano
  openssh
  eza
  bat
  duf
  btop
  htop
  fd
  ripgrep
  zoxide
  net-tools
)

for pkg_name in "${PACKAGES[@]}"; do
    echo -e "${YELLOW}--> Installing ${pkg_name}...${NC}"
    pkg install -y "$pkg_name" || echo -e "${RED}[!] Failed to install ${pkg_name}, continuing...${NC}"
done

# 5. Create Owl Network Stats Script
echo -e "${CYAN}[5/6] Creating Owl ASCII Network Stats widget (~/.owl_stats.sh)...${NC}"
cat << 'OWLEOF' > ~/.owl_stats.sh
#!/usr/bin/env bash

# Terminal Colors
C_OWL='\033[38;5;130m'  # Brown
C_EYES='\033[1;33m'     # Yellow
C_TEXT='\033[1;37m'     # White
C_ACC='\033[1;36m'      # Cyan
C_RST='\033[0m'         # Reset

# Detect active interface
IFACE=$(ip route 2>/dev/null | awk '/default/ {print $5}' | head -n 1)
[ -z "$IFACE" ] && IFACE="wlan0" 

# Get IP
IP=$(ip -c=never -br a show dev "$IFACE" 2>/dev/null | awk '{print $3}' | cut -d/ -f1)
[ -z "$IP" ] && IP="Offline"

USER=$(whoami)

# Calculate Bandwidth
if [ -d "/sys/class/net/$IFACE/statistics" ]; then
    RX1=$(cat /sys/class/net/"$IFACE"/statistics/rx_bytes 2>/dev/null || echo 0)
    TX1=$(cat /sys/class/net/"$IFACE"/statistics/tx_bytes 2>/dev/null || echo 0)
    sleep 1
    RX2=$(cat /sys/class/net/"$IFACE"/statistics/rx_bytes 2>/dev/null || echo 0)
    TX2=$(cat /sys/class/net/"$IFACE"/statistics/tx_bytes 2>/dev/null || echo 0)
else
    RX1=0; TX1=0; RX2=0; TX2=0
    sleep 1
fi

DL_KB=$(( (RX2 - RX1) / 1024 ))
UL_KB=$(( (TX2 - TX1) / 1024 ))

echo -e "${C_OWL}   ,___,   ${C_ACC}Name: ${C_TEXT}${USER}${C_RST}"
echo -e "${C_OWL}   (${C_EYES}o${C_OWL},${C_EYES}o${C_OWL})   ${C_ACC}IP:   ${C_TEXT}${IP} (${IFACE})${C_RST}"
echo -e "${C_OWL}   /)_)\\   ${C_ACC}Down: ${C_TEXT}${DL_KB} KB/s${C_RST}"
echo -e "${C_OWL}    \" \"    ${C_ACC}Up:   ${C_TEXT}${UL_KB} KB/s${C_RST}\n"
OWLEOF

chmod +x ~/.owl_stats.sh

# 6. Configure .bashrc cleanly in default Termux HOME
echo -e "${CYAN}[6/6] Configuring ~/.bashrc...${NC}"

TERMUX_HOME="/data/data/com.termux/files/home"
BASHRC_PATH="${TERMUX_HOME}/.bashrc"

# Backup existing .bashrc if present
[ -f "$BASHRC_PATH" ] && cp "$BASHRC_PATH" "${BASHRC_PATH}.bak"

cat << 'BASHRC' > "$BASHRC_PATH"
# Clean Termux Configuration

# 1. Custom PS1 Prompt ([HH:MM] user:~/path $)
export PS1='\[\033[1;30m\][\t] \[\033[1;32m\]\u\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\]\$ '

# 2. Modern Command Aliases
alias ip="ip -c"
alias ipb="ip -c -br a"
alias ls="eza --icons --group-directories-first"
alias ll="eza -la --icons --git"
alias cat="bat"
alias df="duf"
alias owl="~/.owl_stats.sh"

# 3. Initialize Zoxide (Smart directory jumper)
eval "$(zoxide init bash 2>/dev/null)"

# 4. Display Owl ASCII & Network Info on Launch
[ -f ~/.owl_stats.sh ] && ~/.owl_stats.sh

# 5. Automatically open inside shared Android storage
cd ~/storage/shared 2>/dev/null || cd /sdcard 2>/dev/null
BASHRC

echo -e "\n${GREEN}[✔] Termux setup completed successfully!${NC}"
echo -e "${YELLOW}[!] Reloading shell environment...${NC}\n"

exec bash
