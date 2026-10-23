# goto: clone a repo if it does not exist yet, then land in it.
#
# This is deliberately a shell function instead of a script in ~/.scripts: a
# child process cannot change the state of the shell that called it. Living in
# the shell means `cd`, `export`, `source`, `exec nvim`, ... all behave as if
# you had typed them yourself.
#
#   goto <url>                clone if missing, then cd into the repo
#   goto <url> git            same, but clone with git instead of jj (default)
#   goto <url> -- <cmd...>    clone if missing, cd into it, run <cmd> here
#   goto <url> --print        clone if missing, only print the repo path
#   goto <url> -- cd          explicit cd (same as plain `goto <url>`)
#
# Logging goes to stderr and only --print writes to stdout, so
# `cd "$(goto --print <url>)"` still works.

goto() {
    emulate -L zsh

    local red=$'\e[31m' yellow=$'\e[33m' reset=$'\e[0m'
    local usage_msg='Usage: goto <repository-link> [jj|git] [--print] [-- <command...>]'

    local link='' tool='' print_only=0
    local -a cmd

    while (( $# )); do
        case $1 in
            --)
                shift
                cmd=("$@")
                break
                ;;
            -h | --help)
                print -u2 -r -- "$usage_msg"
                return 0
                ;;
            -p | --print)
                print_only=1
                ;;
            *)
                if [[ -z $link ]]; then
                    link=$1
                elif [[ -z $tool ]]; then
                    tool=$1
                else
                    print -u2 -r -- "${red}Unexpected argument: $1${reset}"
                    print -u2 -r -- "$usage_msg"
                    return 2
                fi
                ;;
        esac
        shift
    done

    if [[ -z $link ]]; then
        print -u2 -r -- "$usage_msg"
        return 2
    fi

    # jj is our default vcs engine if not provided
    : ${tool:=jj}

    if [[ $tool != jj && $tool != git ]]; then
        print -u2 -r -- "${red}Unknown tool '$tool'. Please use 'jj' or 'git'.${reset}"
        return 1
    fi

    # --- normalise the link into an SSH URL + local target dir -------------
    local url=$link domain url_path owner repo repo_path ssh_url target_dir

    # 1. Strip the protocol (http://, https://, ssh://, or git@)
    url=${url#http://}
    url=${url#https://}
    url=${url#ssh://}
    url=${url#git@}

    # Convert the SSH separator ':' to '/' so it parses like an HTTP URL
    url=${url/:/\/}

    # 2. Split into domain and the rest of the path
    domain=${url%%/*}
    url_path=${url#*/}

    # 3. Clean up query parameters, hash fragments, and trailing .git
    url_path=${url_path%%\?*}
    url_path=${url_path%%\#*}
    url_path=${url_path%.git}

    # 4. Extract the actual repo path based on the platform
    if [[ $domain == *github.com* ]]; then
        # GitHub is always domain.com/owner/repo
        owner=${url_path%%/*}
        repo=${url_path#*/}
        repo=${repo%%/*}
        repo_path="$owner/$repo"
    else
        # GitLab uses /-/ as the standard delimiter for UI paths
        repo_path=${url_path%%/-/*}
    fi

    # 5. Construct the final SSH URL
    ssh_url="git@$domain:$repo_path.git"
    target_dir="$HOME/Projects/$domain/$repo_path"

    # --- clone if needed ---------------------------------------------------
    if [[ -d $target_dir ]]; then
        print -u2 -r -- "Repository already exists at: $target_dir"
    else
        mkdir -p -- "${target_dir:h}" || return 1

        if [[ $tool == jj ]]; then
            print -u2 -r -- "Cloning with jj: $ssh_url into $target_dir..."
            jj git clone "$ssh_url" "$target_dir" >&2 || return 1
        else
            print -u2 -r -- "Cloning with git: $ssh_url into $target_dir..."
            git clone "$ssh_url" "$target_dir" >&2 || return 1
        fi

        print -u2 -r -- "${yellow}DONE${reset}"
    fi

    # --- land in the repo --------------------------------------------------
    if (( print_only )); then
        print -r -- "$target_dir"
        return 0
    fi

    builtin cd -- "$target_dir" || return 1

    # Anything after `--` runs in this shell, so `cd`, `export`, ... work
    (( ${#cmd} )) || return 0
    "${cmd[@]}"
}
