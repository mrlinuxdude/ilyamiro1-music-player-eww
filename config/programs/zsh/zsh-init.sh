setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

cd() {
  builtin cd $@ &&
  ls
}

function fetch() {
    local color_file="/tmp/qs_colors.json"
    local config_path="/tmp/qs_fastfetch.jsonc"
    
    # Only rebuild the config if the Matugen colors changed or the config is missing
    if [ "$color_file" -nt "$config_path" ] || [ ! -f "$config_path" ]; then
        
        # Extract analogous cool tones
        local c_blue=$(grep -E '"blue"\s*:\s*"[^"]+"' "$color_file" 2>/dev/null | cut -d '"' -f 4)
        c_blue=${c_blue:-"#89b4fa"}
        
        local c_sapphire=$(grep -E '"sapphire"\s*:\s*"[^"]+"' "$color_file" 2>/dev/null | cut -d '"' -f 4)
        c_sapphire=${c_sapphire:-"#74c7ec"}
        
        local c_teal=$(grep -E '"teal"\s*:\s*"[^"]+"' "$color_file" 2>/dev/null | cut -d '"' -f 4)
        c_teal=${c_teal:-"#94e2d5"}
        
        local c_mauve=$(grep -E '"mauve"\s*:\s*"[^"]+"' "$color_file" 2>/dev/null | cut -d '"' -f 4)
        c_mauve=${c_mauve:-"#cba6f7"}
        
        local c_text=$(grep -E '"text"\s*:\s*"[^"]+"' "$color_file" 2>/dev/null | cut -d '"' -f 4)
        c_text=${c_text:-"#cdd6f4"}

        # Extract a full rainbow palette
        local palette_hexes=()
        for col in red peach yellow green sapphire mauve pink; do
            local val=$(grep -E "\"$col\"\s*:\s*\"[^\"]+\"" "$color_file" 2>/dev/null | cut -d '"' -f 4)
            case $col in
                red) val=${val:-"#f38ba8"} ;;
                peach) val=${val:-"#fab387"} ;;
                yellow) val=${val:-"#f9e2af"} ;;
                green) val=${val:-"#a6e3a1"} ;;
                sapphire) val=${val:-"#74c7ec"} ;;
                mauve) val=${val:-"#cba6f7"} ;;
                pink) val=${val:-"#f5c2e7"} ;;
            esac
            palette_hexes+=("$val")
        done

        # Convert the hex codes into a printable string of ANSI truecolor circles
        local palette_str=""
        for hex in "${palette_hexes[@]}"; do
            hex="${hex//\#/}" # Strip the hash
            local r=$((16#${hex:0:2}))
            local g=$((16#${hex:2:2}))
            local b=$((16#${hex:4:2}))
            palette_str+="\\\\e[38;2;${r};${g};${b}m● \\\\e[0m"
        done

        # Generate the dynamic Fastfetch configuration (Logo colors are now natively inside)
        cat > "$config_path" <<EOF
{
  "\$schema": "https://github.com/fastfetch-cli/fastfetch/raw/master/doc/json_schema.json",
  "logo": {
    "source": "nixos_small",
    "color": {
      "1": "$c_blue",
      "2": "$c_sapphire"
    },
    "padding": {
      "top": 1,
      "left": 2,
      "right": 3
    }
  },
  "display": {
    "separator": "  ",
    "color": {
      "separator": "$c_text"
    }
  },
  "modules": [
    "break",
    {
      "type": "title",
      "format": "{1}",
      "color": {
        "user": "$c_blue"
      }
    },
    "break",
    {
      "type": "os",
      "key": "󱄅 os ",
      "keyColor": "$c_blue"
    },
    {
      "type": "cpu",
      "key": " cpu",
      "keyColor": "$c_sapphire"
    },
    {
      "type": "memory",
      "key": "󰘚 ram",
      "keyColor": "$c_teal"
    },
    {
      "type": "shell",
      "key": " sh ",
      "keyColor": "$c_mauve"
    },
    "break",
    {
      "type": "command",
      "key": " ",
      "text": "echo -e '$palette_str'"
    }
  ]
}
EOF
    fi

    # Run Fastfetch instantly using the cached config
    fastfetch -c "$config_path"
}
 
pasteimg() {
    local name="${1:-clipboard.png}"
    [[ "$name" != *.png ]] && name="$name.png"
    wl-paste --type image/png | sudo tee "$name" > /dev/null
}

stsetup() {
    local proj_dir="$HOME/Projects/stewart-new"
    
    if [[ ! -d "$proj_dir" ]]; then
        echo "Directory $proj_dir does not exist."
        return 1
    fi

    cd "$proj_dir" || return 1

    kitty --directory "$proj_dir" nix develop --command zsh -ic "alias run='python main.py'; exec zsh" &
    
    sleep 0.5
    
    hyprctl dispatch splitratio -0.5

    nix develop --command zsh -ic "edit; exec zsh"
}

fetch
