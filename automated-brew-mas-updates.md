# Automated Homebrew + Mac App Store Updates on macOS

This guide sets up a scheduled job that runs:

```bash
brew update && brew upgrade && brew cleanup && mas upgrade
```

with:

- no sudo for Homebrew
- passwordless sudo **only** for `mas upgrade`
- no hanging prompts
- no reboot required

This is intended for a **single-user personal Mac**.

---

## Prerequisites

- You are signed into the Mac App Store on this account
- Homebrew is installed
- `mas` is installed via Homebrew

```bash
brew install mas
```

Confirm the binary location:

```bash
command -v mas
# Expected: /opt/homebrew/bin/mas
```

---

## Step 1: Create the update script

Create a bin directory if needed:

```bash
mkdir -p ~/bin
```

Create the script:

```bash
nano ~/bin/update-tools.sh
```

Paste the following:

```bash
#!/usr/bin/env bash
set -euo pipefail

# launchd has a minimal PATH
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

LOG="$HOME/Library/Logs/update-tools.log"
mkdir -p "$(dirname "$LOG")"
exec >>"$LOG" 2>&1

echo "===== $(date) starting updates ====="

# Homebrew (never sudo)
brew update
brew upgrade
brew cleanup

# Mac App Store updates (sudo, non-interactive)
sudo -n /opt/homebrew/bin/mas upgrade

echo "===== $(date) finished updates ====="
```

Make it executable:

```bash
chmod +x ~/bin/update-tools.sh
```

Test it manually:

```bash
~/bin/update-tools.sh
```

At this stage, `mas` will still prompt for a password. That is expected.

---

## Step 2: Allow passwordless sudo for `mas upgrade`

Edit sudoers safely:

```bash
sudo visudo
```

Add **exactly** this line (replace `jpdck` if needed):

```sudoers
jpdck ALL=(root) NOPASSWD: /opt/homebrew/bin/mas upgrade
```

Save and exit.

### Verify sudo configuration

Run:

```bash
sudo -l -U jpdck
```

You must see:

```text
(root) NOPASSWD: /opt/homebrew/bin/mas upgrade
```

Now test non-interactive sudo:

```bash
sudo -k
sudo -n /opt/homebrew/bin/mas upgrade
```

This must run without prompting.

---

## Step 3: Create the LaunchAgent

Create the LaunchAgents directory if needed:

```bash
mkdir -p ~/Library/LaunchAgents
```

Create the plist:

```bash
nano ~/Library/LaunchAgents/com.jpdck.update-tools.plist
```

Paste:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.jpdck.update-tools</string>

  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>-lc</string>
    <string>~/bin/update-tools.sh</string>
  </array>

  <!-- Run daily at 10:15 -->
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key><integer>10</integer>
    <key>Minute</key><integer>15</integer>
  </dict>

  <key>RunAtLoad</key>
  <true/>

  <key>StandardOutPath</key>
  <string>~/Library/Logs/update-tools.out</string>
  <key>StandardErrorPath</key>
  <string>~/Library/Logs/update-tools.err</string>
</dict>
</plist>
```

Load the agent:

```bash
launchctl load -w ~/Library/LaunchAgents/com.jpdck.update-tools.plist
```

Confirm it is loaded:

```bash
launchctl list | grep update-tools
```

---

## Logs and troubleshooting

Logs are written to:

- `~/Library/Logs/update-tools.log`
- `~/Library/Logs/update-tools.out`
- `~/Library/Logs/update-tools.err`

If something breaks:

- Brew failures are usually transient
- `mas` failures usually mean you are signed out of the App Store
- Sudo failures mean the sudoers rule no longer matches

You can always re-test sudo with:

```bash
sudo -k
sudo -n /opt/homebrew/bin/mas upgrade
```

---

## Security notes

- Do not run `brew` with sudo
- Do not broaden the sudoers rule
- Do not use this on shared or managed machines
- This setup intentionally trades a small amount of security purity for unattended convenience

---

## Done

Your Mac now updates itself quietly, without prompting, and without doing anything clever enough to regret later.
