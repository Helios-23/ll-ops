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

# Sequential execution logic (type commands exactly like the command line) add -e=clean_dist=true
run_playbook apb build.yml -t pharos_build -e target=linux-x86_64-gnu && \
run_playbook apb deploy.yml -t pharos_runtime -l web0 && \
# for app deploys add  -e=clean_dist=true and/or -e clean_dest=true 
run_playbook apb deploy.yml -t pharos_app -l web0 -e app_id=ucal -e clean_dist=true -e clean_dest=true && \
run_playbook apb deploy.yml -t pharos_app -l web0 -e app_id=dev_docs -e clean_dist=true -e clean_dest=true && \
