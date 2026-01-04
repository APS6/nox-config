source /usr/share/cachyos-fish-config/cachyos-config.fish

# Disable fastfetch greeting
function fish_greeting
end

# Starship prompt
starship init fish | source

zoxide init fish | source
mise activate fish | source
