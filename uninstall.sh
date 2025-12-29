#!/bin/bash
#
# WaterFurnace Aurora Uninstall Script
# Removes the WaterFurnace Aurora gem and associated services
# Useful for testing installation procedures
#

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Gems that were installed (primary gems to remove)
GEMS_TO_REMOVE=("waterfurnace_aurora")
# Optional dependency gems that may be orphaned
OPTIONAL_DEPS=("rake" "rmodbus" "ccutrer-serialport" "mqtt-homie")

# System packages that may have been installed (Debian/Ubuntu)
SYSTEM_PACKAGES=("ruby" "ruby-dev" "build-essential")

# MQTT broker packages (optional)
MQTT_PACKAGES=("mosquitto" "mosquitto-clients")

SERVICE_NAME="aurora_mqtt_bridge"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

# Print functions
print_header() {
    echo -e "\n${BLUE}===================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ ${NC} $1"
}

print_error() {
    echo -e "${RED}✗ ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠ ${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ ${NC} $1"
}

# Ask yes/no question
ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"

    if [ "$default" = "y" ]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi

    while true; do
        read -p "$prompt" response
        response=${response:-$default}
        case "$response" in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Check for sudo if needed
check_privileges() {
    if [ "$EUID" -ne 0 ]; then
        print_warning "This script requires sudo privileges for removing system services"
        if ! sudo -v; then
            print_error "Failed to obtain sudo privileges"
            exit 1
        fi
        SUDO="sudo"
    else
        SUDO=""
    fi
}

# Stop and remove MQTT bridge service
remove_mqtt_bridge_service() {
    print_header "Removing MQTT Bridge Service"

    if [ -f "$SERVICE_FILE" ]; then
        print_info "Found service file: $SERVICE_FILE"

        # Check if service is running
        if $SUDO systemctl is-active --quiet $SERVICE_NAME; then
            print_info "Stopping service..."
            $SUDO systemctl stop $SERVICE_NAME
            print_success "Service stopped"
        fi

        # Check if service is enabled
        if $SUDO systemctl is-enabled --quiet $SERVICE_NAME 2>/dev/null; then
            print_info "Disabling service..."
            $SUDO systemctl disable $SERVICE_NAME
            print_success "Service disabled"
        fi

        # Remove service file
        print_info "Removing service file..."
        $SUDO rm -f "$SERVICE_FILE"
        $SUDO systemctl daemon-reload
        print_success "Service file removed"
    else
        print_info "Service file not found, skipping"
    fi
}

# Remove udev rule for ttyHeatPump symlink
remove_device_symlink() {
    print_header "Removing Device Symlink"

    local udev_rule_file="/etc/udev/rules.d/99-waterfurnace-heatpump.rules"

    if [ -f "$udev_rule_file" ]; then
        print_info "Found udev rule: $udev_rule_file"

        # Show what it's linked to if symlink exists
        if [ -e /dev/ttyHeatPump ]; then
            print_info "Current symlink: /dev/ttyHeatPump -> $(readlink -f /dev/ttyHeatPump)"
        fi

        print_info "Removing udev rule..."
        $SUDO rm -f "$udev_rule_file"

        # Reload udev rules
        if command -v udevadm &> /dev/null; then
            $SUDO udevadm control --reload-rules
            $SUDO udevadm trigger --subsystem-match=tty
        fi

        print_success "Device symlink rule removed"

        # The symlink will disappear on next device reconnection or reboot
        if [ -e /dev/ttyHeatPump ]; then
            print_info "Note: /dev/ttyHeatPump will be removed on next device reconnection or reboot"
        fi
    else
        print_info "Udev rule not found, skipping"
    fi
}

# Final system cleanup
final_cleanup() {
    print_header "Final System Cleanup"

    # Clean up leftover RubyGems directories
    if ask_yes_no "Remove leftover RubyGems directories?" "y"; then
        print_info "Cleaning up RubyGems directories..."
        [ -d /var/lib/gems ] && $SUDO rm -rf /var/lib/gems && print_success "Removed /var/lib/gems"
        [ -d /usr/local/lib/ruby ] && $SUDO rm -rf /usr/local/lib/ruby && print_success "Removed /usr/local/lib/ruby"
        [ -d ~/.gem ] && rm -rf ~/.gem && print_success "Removed ~/.gem"
    fi

    # Clean up package manager cache and orphaned packages
    if command -v apt-get &> /dev/null; then
        print_info "Cleaning up package manager..."
        $SUDO apt-get autoremove -y
        $SUDO apt-get clean
        print_success "Package manager cleaned"
    fi
}

# Remove MQTT broker
remove_mqtt_broker() {
    print_header "MQTT Broker Removal"

    # Remove configuration files (regardless of whether Mosquitto is being removed)
    local config_removed=false
    local config_file_localhost="/etc/mosquitto/conf.d/local-only.conf"
    local config_file_external="/etc/mosquitto/conf.d/allow-external.conf"

    if [ -f "$config_file_localhost" ]; then
        print_info "Removing Mosquitto localhost-only configuration..."
        $SUDO rm -f "$config_file_localhost"
        print_success "Localhost-only configuration removed"
        config_removed=true
    fi

    if [ -f "$config_file_external" ]; then
        print_info "Removing Mosquitto external access configuration..."
        $SUDO rm -f "$config_file_external"
        print_success "External access configuration removed"
        config_removed=true
    fi

    # Restart mosquitto if config was removed and it's still running
    if [ "$config_removed" = true ]; then
        if command -v mosquitto &> /dev/null && $SUDO systemctl is-active --quiet mosquitto 2>/dev/null; then
            $SUDO systemctl restart mosquitto 2>/dev/null || true
        fi
    fi

    if command -v mosquitto &> /dev/null; then
        print_warning "Mosquitto MQTT broker is installed"

        if ask_yes_no "Remove Mosquitto MQTT broker?" "n"; then
            if command -v apt-get &> /dev/null; then
                $SUDO systemctl stop mosquitto 2>/dev/null || true
                $SUDO systemctl disable mosquitto 2>/dev/null || true
                print_info "Removing MQTT packages: ${MQTT_PACKAGES[*]}"
                $SUDO apt-get remove --purge -y "${MQTT_PACKAGES[@]}"
                print_success "Mosquitto removed"
            else
                print_warning "Cannot automatically remove Mosquitto on this system"
                print_info "Please remove it manually"
            fi
        else
            print_info "Keeping Mosquitto installed"
        fi
    else
        print_info "Mosquitto not installed, skipping"
    fi
}

# Remove system packages
remove_system_packages() {
    print_header "System Packages Removal"

    print_warning "The following packages were potentially installed by the installation script:"
    for pkg in "${SYSTEM_PACKAGES[@]}"; do
        print_info "  - $pkg"
    done
    echo
    print_warning "These packages may be used by other software on your system!"
    echo

    if ask_yes_no "Remove these system packages?" "n"; then
        if command -v apt-get &> /dev/null; then
            print_info "Removing packages: ${SYSTEM_PACKAGES[*]}"
            $SUDO apt-get remove --purge -y "${SYSTEM_PACKAGES[@]}"
            print_success "System packages removed"
        else
            print_warning "Cannot automatically remove packages on this system"
            print_info "Please remove them manually if desired"
        fi
    else
        print_info "Keeping system packages installed"
    fi
}

# Remove user from dialout group
remove_user_permissions() {
    print_header "User Permissions"

    local current_user="${SUDO_USER:-$USER}"

    if groups "$current_user" | grep -q '\bdialout\b'; then
        print_info "User '$current_user' is in the dialout group"

        print_warning "Removing from dialout group may affect access to serial devices for other applications"

        if ask_yes_no "Remove user '$current_user' from dialout group?" "n"; then
            $SUDO gpasswd -d "$current_user" dialout
            print_success "User removed from dialout group"
            print_warning "You may need to log out and back in for this change to take effect"
        else
            print_info "Keeping user in dialout group"
        fi
    else
        print_info "User '$current_user' is not in the dialout group, skipping"
    fi
}

# Clean up any configuration files
cleanup_configs() {
    print_header "Configuration Cleanup"

    local config_locations=(
        "$HOME/.waterfurnace_aurora"
        "$HOME/.config/waterfurnace_aurora"
        "$HOME/waterfurnace_aurora"
    )

    local found_configs=false
    for config in "${config_locations[@]}"; do
        if [ -e "$config" ]; then
            found_configs=true
            print_info "Found config: $config"
        fi
    done

    if [ "$found_configs" = true ]; then
        if ask_yes_no "Remove configuration files?" "y"; then
            for config in "${config_locations[@]}"; do
                if [ -e "$config" ]; then
                    rm -rf "$config"
                    print_success "Removed $config"
                fi
            done
        else
            print_info "Keeping configuration files"
        fi
    else
        print_info "No configuration files found"
    fi
}

# Show summary
show_summary() {
    print_header "Uninstall Complete"

    print_success "WaterFurnace Aurora has been uninstalled"

    echo -e "\n${BLUE}What was removed:${NC}\n"
    echo "  • WaterFurnace Aurora gem and executables"
    echo "  • Systemd service (if present)"
    echo "  • Device symlink /dev/ttyHeatPump (if present)"
    echo "  • Any selected optional components"

    echo -e "\n${GREEN}System is clean and ready for fresh installation!${NC}\n"
}

# Main uninstall flow
main() {
    print_header "WaterFurnace Aurora Uninstall Script"

    echo "This script will remove the WaterFurnace Aurora gem and associated components."
    echo "This is useful for testing fresh installations."
    echo

    print_warning "This will remove installed software from your system!"
    echo

    if ! ask_yes_no "Continue with uninstall?" "n"; then
        echo "Uninstall cancelled."
        exit 0
    fi

    # Run uninstall steps
    check_privileges
    remove_mqtt_bridge_service
    remove_device_symlink
    remove_mqtt_broker
    cleanup_configs
    remove_user_permissions
    remove_system_packages
    final_cleanup
    show_summary
}

# Run main function
main "$@"
