
# start: Octopus CLI (octo) Autocomplete script
_octo_zsh_complete()
{
    local completions=("$(octo complete $words)")
    reply=( "${(ps:\n:)completions}" )
}
compctl -K _octo_zsh_complete octo
compctl -K _octo_zsh_complete Octo
# end: Octopus CLI (octo) Autocomplete script
