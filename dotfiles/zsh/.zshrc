# ── ~/.zshrc ─────────────────────────────────────────────────────────────────
# Raw, portable zsh config (symlinked). Works on NixOS and Arch: plugins are
# sourced from the first path that exists, so no hardcoded /nix/store paths.

# ── History ──────────────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE INC_APPEND_HISTORY EXTENDED_HISTORY

# ── Behaviour ────────────────────────────────────────────────────────────────
setopt AUTO_CD              # `foo/` cds into foo
setopt INTERACTIVE_COMMENTS # allow # comments at the prompt
bindkey -e                  # emacs keybindings (Ctrl-a/e/r etc.)

# ── Completion ───────────────────────────────────────────────────────────────
autoload -Uz compinit && compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ── Helper: source the first readable file from a list ───────────────────────
_src() { local f; for f in "$@"; do [[ -r $f ]] && source "$f" && return 0; done; return 1; }

# ── Aliases (utilities, guarded so they no-op if not installed) ──────────────
if command -v eza >/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -l --icons --git --group-directories-first'
  alias la='eza -la --icons --git --group-directories-first'
  alias lt='eza --tree --level=2 --icons'
fi
command -v bat >/dev/null && alias cat='bat --paging=never'

# ── fzf: Ctrl-R history, Ctrl-T files, ** completion ─────────────────────────
if command -v fzf >/dev/null; then
  if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)                       # fzf >= 0.48 ships integration
  else
    for d in /usr/share/fzf /usr/share/doc/fzf/examples \
             /run/current-system/sw/share/fzf "$HOME/.nix-profile/share/fzf"; do
      [[ -r $d/key-bindings.zsh ]] && source "$d/key-bindings.zsh"
      [[ -r $d/completion.zsh ]]   && source "$d/completion.zsh"
    done
  fi
  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border=rounded"
fi

# ── Autosuggestions (fish-style greyed type-ahead) ───────────────────────────
# On NixOS these load via /etc/zshrc (programs.zsh.autosuggestions). Only source
# manually if not already active — e.g. on Arch.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
if (( ! ${+functions[_zsh_autosuggest_start]} )); then
  _src /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
       /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# ── Prompt (Starship, themed from matugen) ───────────────────────────────────
command -v starship >/dev/null && eval "$(starship init zsh)"

# ── fastfetch: run on demand with `ff` (no auto-greeting on every shell) ─────
command -v fastfetch >/dev/null && alias ff='fastfetch'

# ── Syntax highlighting (NixOS: via /etc/zshrc; else source last) ────────────
if (( ! ${+functions[_zsh_highlight]} )); then
  _src /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
       /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Drop the green "valid command" / red "invalid" coloring — keep typing neutral.
# (Quoted strings, brackets, etc. stay subtly highlighted.)
typeset -gA ZSH_HIGHLIGHT_STYLES
for _k in command builtin alias function precommand hashed-command unknown-token; do
  ZSH_HIGHLIGHT_STYLES[$_k]='none'
done
unset _k
