# Enable alias expansion inside functions for Zsh
setopt local_options aliases

run_playbook() {
    if [ -z "$1" ]; then
        echo "Error: No command specified."
        return 1
    fi
    # 'eval' forces Zsh to expand aliases
    eval "$@"

    if [ $? -ne 0 ]; then
        echo "Error: $* failed. Stopping sequence."
        return 1
    fi
}

# Sequential execution logic (type commands exactly like the command line)
run_playbook apb build.yml -t lantern_build -e target=linux-x86_64-gnu && \
run_playbook apb deploy.yml -t lantern_runtime -l web0 && \
run_playbook apb deploy.yml -t lantern_app -l web0 && \
