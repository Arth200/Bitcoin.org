#!/bin/bash

# Function to print usage information
print_usage() {
    cat >&2 <<EOF
Usage: $(basename "$0") [--bg=dark] [--palette=linux|solarized|solarized-xterm|tango|xterm]

Convert ANSI codes in data passed to stdin to HTML.

Options:
  --bg=dark                  Use a dark background (optional)
  --palette=palette_name     Choose color palette (optional)
                             Available palettes: linux, solarized, solarized-xterm, tango, xterm

Examples:
  ls -l --color=always | $(basename "$0") --bg=dark > ls.html
  git show --color | $(basename "$0") > git_show.html
EOF
    exit 1
}

# Initialize default values
palette="linux"
dark_bg=""

# Parse command-line options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --bg=dark)
            dark_bg="yes"
            shift
            ;;
        --palette=*)
            palette="${1#*=}"
            shift
            ;;
        --help)
            print_usage
            ;;
        *)
            print_usage
            ;;
    esac
done

# Define color palettes using arrays
declare -A colors
colors[linux]="000000 AA0000 00AA00 AA5500 0000AA AA00AA 00AAAA AAAAAA 555555 FF5555 55FF55 FFFF55 5555FF FF55FF 55FFFF FFFFFF"
colors[solarized]="073642 D30102 859900 B58900 268BD2 D33682 2AA198 EEE8D5 002B36 CB4B16 586E75 657B83 839496 6C71C4 93A1A1 FDF6E3"
colors[solarized-xterm]="262626 AF0000 5F8700 AF8700 0087FF AF005F 00AFAF E4E4E4 1C1C1C D75F00 585858 626262 808080 5F5FAF 8A8A8A FFFFD7"
colors[tango]="000000 CC0000 4E9A06 C4A000 3465A4 75507B 06989A D3D7CF 555753 EF2929 8AE234 FCE94F 729FCF AD7FA8 34E2E2 EEEECC"
colors[xterm]="000000 CD0000 00CD00 CDCD00 0000EE CD00CD 00CDCD E5E5E5 7F7F7F FF0000 00FF00 FFFF00 5C5CFF FF00FF 00FFFF FFFFFF"

# Select palette based on user input
if [[ -n "${colors[$palette]}" ]]; then
    colors_arr=(${colors[$palette]})
else
    echo "Error: Invalid palette '$palette'. Defaulting to 'linux'." >&2
    colors_arr=(${colors[linux]})
fi

# Generate HTML header and CSS
generate_css() {
    cat <<EOF
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<style type="text/css">
pre { white-space: pre-wrap; margin: 40px; line-height: 1.5em; }
EOF

    # Print base colors and bold settings
    local base_fg="#${colors_arr[0]}"
    local base_bg="#${colors_arr[15]}"
    local bold_fg="#${colors_arr[7]}"
    local bold_bg="#${colors_arr[0]}"
    
    cat <<EOF
.ef0,.f0 { color: $base_fg; } .eb0,.b0 { background-color: $base_bg; }
.ef1,.f1 { color: #${colors_arr[1]}; } .eb1,.b1 { background-color: #${colors_arr[1]}; }
.ef2,.f2 { color: #${colors_arr[2]}; } .eb2,.b2 { background-color: #${colors_arr[2]}; }
.ef3,.f3 { color: #${colors_arr[3]}; } .eb3,.b3 { background-color: #${colors_arr[3]}; }
.ef4,.f4 { color: #${colors_arr[4]}; } .eb4,.b4 { background-color: #${colors_arr[4]}; }
.ef5,.f5 { color: #${colors_arr[5]}; } .eb5,.b5 { background-color: #${colors_arr[5]}; }
.ef6,.f6 { color: #${colors_arr[6]}; } .eb6,.b6 { background-color: #${colors_arr[6]}; }
.ef7,.f7 { color: #${colors_arr[7]}; } .eb7,.b7 { background-color: #${colors_arr[7]}; }
.ef8, .f0 > .bold,.bold > .f0 { color: #${colors_arr[8]}; font-weight: normal; }
.ef9, .f1 > .bold,.bold > .f1 { color: #${colors_arr[9]}; font-weight: normal; }
.ef10,.f2 > .bold,.bold > .f2 { color: #${colors_arr[10]}; font-weight: normal; }
.ef11,.f3 > .bold,.bold > .f3 { color: #${colors_arr[11]}; font-weight: normal; }
.ef12,.f4 > .bold,.bold > .f4 { color: #${colors_arr[12]}; font-weight: normal; }
.ef13,.f5 > .bold,.bold > .f5 { color: #${colors_arr[13]}; font-weight: normal; }
.ef14,.f6 > .bold,.bold > .f6 { color: #${colors_arr[14]}; font-weight: normal; }
.ef15,.f7 > .bold,.bold > .f7 { color: #${colors_arr[15]}; font-weight: normal; }
EOF

    # Print colors from color palette
    local idx=16
    for ((i=0; i<16; i++)); do
        local r=$(( (i / 36) * 40 + 55 ))
        local g=$(( ((i / 6) % 6) * 40 + 55 ))
        local b=$(( (i % 6) * 40 + 55 ))
        cat <<EOF
.ef$idx { color: #$(printf "%2.2x%2.2x%2.2x" $r $g $b); }
.eb$idx { background-color: #$(printf "%2.2x%2.2x%2.2x" $r $g $b); }
EOF
        (( idx++ ))
    done

    # Print grayscale colors
    for ((i=0; i<24; i++)); do
        local gray=$(( 232 + i ))
        local gray_value=$(( i * 10 + 8 ))
        cat <<EOF
.ef$idx { color: #$(printf "%2.2x%2.2x%2.2x" $gray_value $gray_value $gray_value); }
.eb$idx { background-color: #$(printf "%2.2x%2.2x%2.2x" $gray_value $gray_value $gray_value); }
EOF
        (( idx++ ))
    done

    # Print styles for reverse, underline, blink, etc.
    cat <<EOF
.f9 { color: $(if [[ -n "$dark_bg" ]]; then echo "$base_bg;"; else echo "$base_fg;"; fi) }
.b9 { background-color: $(if [[ -n "$dark_bg" ]]; then echo "$base_fg"; else echo "$base_bg"; fi); }
.f9 > .bold,.bold > .f9, body.f9 > pre > .bold {
    color: $(if [[ -n "$dark_bg" ]]; then echo "$bold_fg;"; else echo "$bold_bg;"; fi)
    font-weight: $(if [[ -n "$dark_bg" ]]; then echo 'normal;'; else echo 'bold;'; fi)
}
.reverse {
    color: #$base_fg; background-color: #$base_bg;
}
.underline { text-decoration: underline; }
.line-through { text-decoration: line-through; }
.blink { text-decoration: blink; }
EOF

    cat <<EOF
</style>
</head>
<body>
<pre>
EOF
}

# Convert ANSI codes to HTML
ansi_to_html() {
    sed -r -e 's/\033\[([0-9;]*m)//g' \
        -e 's/\033\[([0-9;]+)H/\n/g' \
        -e 's/\033\[([0-9;]+)J/<span class="f&1">/g' \
        -e 's/\033\[([0-9;]+)K/<span class="b&1">/g' \
        -e 's/\033\[([0-9;]+)m/<span class="f&1">/g' \
        -e 's/\033\[0m/<\/span>/g'
}

# Generate output HTML
generate_html() {
    generate_css
    ansi_to_html
    cat <<EOF
</pre>
</body>
</html>
EOF
}

# Run the HTML generation
generate_html
