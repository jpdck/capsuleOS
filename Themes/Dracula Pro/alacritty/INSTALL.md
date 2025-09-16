### [Alacritty](https://github.com/alacritty/alacritty)

#### Usage

To activate the theme in **Alacritty**, you need to modify its configuration file.

**Alacritty** does not create this configuration file for you, but it looks for one in the following locations:

**Linux**:

- `$XDG_CONFIG_HOME/alacritty/alacritty.toml`
- `$XDG_CONFIG_HOME/alacritty.toml`

**macOS**:

- `$HOME/.config/alacritty/alacritty.toml`
- `$HOME/.alacritty.toml`

**Windows**:

- `%APPDATA%\alacritty\alacritty.toml`

#### Installation

1. Copy the theme files next to your `alacritty.toml` configuration file.
2. Import the desired theme configuration in your `alacritty.toml` file:

```toml
import = [
  "~/.config/alacritty/dracula-pro-alucard.toml"
]
```

> Applying the theme will take effect immediately. If not, restart Alacritty.
