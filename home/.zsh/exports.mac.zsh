# Mac-specific exports

# Rust toolchain. Homebrew's rustup keeps its shims in its own prefix and uses
# RUSTUP_HOME=~/.rustup, so there is no ~/.cargo/bin on a brew-based install.
[[ -d /opt/homebrew/opt/rustup/bin ]] && export PATH="/opt/homebrew/opt/rustup/bin:$PATH"
[[ -d "$HOME/.cargo/bin" ]] && export PATH="$HOME/.cargo/bin:$PATH"
