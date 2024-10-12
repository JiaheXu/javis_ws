#!/usr/bin/env bash
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
eval "$(cat $__dir/../../javis_utils/scripts/header.sh)"
eval "$(cat $__dir/../../javis_utils/scripts/formatters.sh)"

if [[ ! -z $JAVIS_OPERATIONS ]]; then
    DEFAULT_CONFIG=$JAVIS_OPERATIONS/javis_deploy/sync_configurations.yaml
fi

if chk_flag --help $@ || chk_flag help $@ || chk_flag -h $@ || chk_flag -help $@; then
    title "$__file_name <options> -- < systems >"
    text "    uses rsync to sync the workspace on other hosts"
    text
    text "Options:"
    text "  --payloads               : rather than specifying hosts, automatically select all connected javis payloads"
    text "  --connected              : rather than specifying hosts, automatically select all connected javis hosts"
    text
    text "    systems         : comma delimited names of the systems to install on"
    text "                      if none are provided it will default to localhost"
    exit_success
fi

# //////////////////////////////////////////////////////////////////////////////
# @brief run the ansible robot playbook
# //////////////////////////////////////////////////////////////////////////////

system_names=""
if chk_flag --connected $@ ; then
    javis_names=$(javis-hosts complete_helper)
    if ! last_command_failed; then
        system_names=$javis_names
    fi
elif chk_flag --payloads $@ ; then
    javis_names=$(javis-hosts complete_helper --payloads)
    if ! last_command_failed; then
        system_names=$javis_names
    fi
else
    sidx=$(($(get_idx -- $@) + 2))
    if ! last_command_failed; then
        for name in "${@:$sidx}"; do
            system_names="$name $system_names"
        done
    fi
fi
if [[ -z $system_names ]]; then
    error "Please specify a target system"
    exit 1
fi

for host in $system_names; do
    title Syncing $host
    sshpass -p passme24 ssh -t $host "echo passme24 | sudo -S date -s \"$(date +'%D %T.%N')\""
done
