# Sourced by every zsh invocation (login/non-login, interactive/non-interactive).
# Ensures ~/.local/bin (where AI CLIs like agy install) is on PATH for nvim
# terminals and non-interactive shells that do not source ~/.zshrc.
export PATH="$HOME/.local/bin:$PATH"
