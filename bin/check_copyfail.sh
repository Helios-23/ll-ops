#!/bin/bash
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo "=== CVE-2026-31431 (Copy Fail) Checker ==="
echo ""

# Check Ubuntu 22+
if [ -f /etc/os-release ]; then
    source /etc/os-release
    if [[ "$ID" == "ubuntu" ]]; then
        major=${VERSION_ID%%.*}
        [[ "$major" -ge 22 ]] && echo -e "${GREEN}Ubuntu $VERSION_ID detected${NC}" || echo -e "${YELLOW}Ubuntu $VERSION_ID (expect 22+)${NC}"
    fi
fi

# Check kernel version (vulnerable: 4.14+ to unpatched)
kernel=$(uname -r)
echo "Kernel: $kernel"
major=$(echo "$kernel" | cut -d. -f1)
minor=$(echo "$kernel" | cut -d. -f2)

# Patched in 6.18.22+, 6.19.12+, 7.0+
vulnerable=true
if [[ "$major" -ge 7 ]] || [[ "$major" -eq 6 && "$minor" -ge 20 ]]; then
    vulnerable=false
fi
[[ "$vulnerable" == "true" ]] && echo -e "${RED}Kernel potentially vulnerable${NC}" || echo -e "${GREEN}Kernel appears patched${NC}"

# Test if AF_ALG socket + algif_aead is accessible (exploit precondition)
exploit_runnable=false
echo ""
echo "Testing exploit preconditions..."

if python3 -c "import socket; s=socket.socket(38,socket.SOCK_SEQPACKET,0); s.close()" 2>/dev/null; then
    echo -e "${RED}AF_ALG socket: ACCESSIBLE${NC}"
    # Check if algif_aead is available
    if [ -d /sys/module/algif_aead ] || grep -q algif_aead /proc/modules 2>/dev/null; then
        echo -e "${RED}algif_aead: AVAILABLE${NC}"
        exploit_runnable=true
    else
        echo -e "${YELLOW}algif_aead: not loaded (may be built-in)${NC}"
    fi
else
    echo -e "${GREEN}AF_ALG socket: RESTRICTED${NC}"
fi

# Check KASLR status
echo ""
if grep -q kaslr /proc/cmdline 2>/dev/null; then
    echo -e "${GREEN}KASLR: ENABLED${NC}"
    kaslr_enabled=true
else
    echo -e "${YELLOW}KASLR: NOT enabled${NC}"
    kaslr_enabled=false
fi

# Verdict
echo ""
echo "=== Result ==="
if [[ "$exploit_runnable" == "true" && "$vulnerable" == "true" ]]; then
    echo -e "${RED}EXPLOIT IS RUNNABLE on this system${NC}"
    echo ""
    read -p "Apply temporary mitigations? (y/n) " -n 1 -r; echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        [[ $EUID -ne 0 ]] && { echo "Run with sudo"; exit 1; }
        
        echo "1. Restricting AF_ALG access..."
        echo "install algif_aead /bin/false" > /etc/modprobe.d/disable-algif.conf
        echo "install af_alg /bin/false" >> /etc/modprobe.d/disable-algif.conf
        rmmod algif_aead 2>/dev/null || echo "algif_aead not loaded or built-in"
        rmmod af_alg 2>/dev/null || true
        echo -e "${GREEN}AF_ALG access restricted${NC}"
        
        echo "2. Enabling KASLR..."
        if [[ "$kaslr_enabled" == "false" ]] && [ -f /etc/default/grub ]; then
            cp /etc/default/grub /etc/default/grub.backup
            sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="kaslr /' /etc/default/grub
            update-grub 2>/dev/null || grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
            echo -e "${GREEN}KASLR enabled (reboot required)${NC}"
        else
            echo "KASLR already enabled or GRUB not found"
        fi
        echo -e "${GREEN}Mitigations applied. REBOOT REQUIRED.${NC}"
    fi
else
    echo -e "${GREEN}Exploit not runnable - system not vulnerable or preconditions not met${NC}"
fi
