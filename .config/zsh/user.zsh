#  Startup 
# Commands to execute on startup (before the prompt is shown)
# Check if the interactive shell option is set
if [[ $- == *i* ]]; then
    # This is a good place to load graphic/ascii art, display system information, etc.
    if command -v pokego >/dev/null; then
        pokego --no-title -r 1,3,6
    elif command -v pokemon-colorscripts >/dev/null; then
        pokemon-colorscripts --no-title -r 1,3,6
    elif command -v fastfetch >/dev/null; then
        if do_render "image"; then
            fastfetch --logo-type kitty
        fi
    fi
fi

#   Overrides 
# Unset HYDE_ZSH_PROMPT to disable HyDE's default prompt (like p10k)
# and allow Oh My Zsh themes to be used instead.
unset HYDE_ZSH_PROMPT

if [[ ${HYDE_ZSH_NO_PLUGINS} != "1" ]]; then
    #  OMZ Theme 
    # Set the Oh My Zsh theme you want to use.
    ZSH_THEME="gruvbox"
    SOLARIZED_THEME="dark"

    #  OMZ Plugins 
    # manually add your oh-my-zsh plugins here
    plugins=(
        "git"
        "sudo"
    )
fi
