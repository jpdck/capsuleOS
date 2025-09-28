# Load Cargo environment if it exists
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# Conda initialization - early setup for consistent behavior
if command -v conda >/dev/null 2>&1; then
  eval "$(conda shell.zsh hook 2>/dev/null)"
  # Ensure base environment is always activated
  if [[ -z "$CONDA_DEFAULT_ENV" ]]; then
    conda activate base 2>/dev/null
  fi
fi