# Herdr: run the server as a launchd agent at login.
#
# `brew services start herdr` also uses launchd, but launchd jobs are not
# session leaders, so herdr reports detached_server_daemon=false and every
# remote attach asks "restart the remote server now?". This agent runs the
# server through herdr/herdr-daemon.pl, which forks + setsid()s first so the
# server is a session leader and the prompt goes away.

if [[ "$OSTYPE" == darwin* && -x /opt/homebrew/opt/herdr/bin/herdr ]]; then
    herdr_label="net.dolkens.herdr"
    herdr_plist="$HOME/Library/LaunchAgents/$herdr_label.plist"
    herdr_wrapper="$HOME/.zsh-profile/herdr/herdr-daemon.pl"
    herdr_log="$HOME/.config/herdr/launchd.log"

    herdr_desired=$(cat <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>$herdr_label</string>
	<key>ProgramArguments</key>
	<array>
		<string>/usr/bin/perl</string>
		<string>$herdr_wrapper</string>
		<string>/opt/homebrew/opt/herdr/bin/herdr</string>
		<string>server</string>
	</array>
	<key>EnvironmentVariables</key>
	<dict>
		<key>PATH</key>
		<string>/opt/homebrew/bin:/opt/homebrew/sbin:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
	</dict>
	<key>RunAtLoad</key>
	<true/>
	<key>KeepAlive</key>
	<true/>
	<key>StandardOutPath</key>
	<string>$herdr_log</string>
	<key>StandardErrorPath</key>
	<string>$herdr_log</string>
</dict>
</plist>
PLIST
)

    if [[ ! -f $herdr_plist ]] || [[ "$(<$herdr_plist)" != "$herdr_desired" ]]; then
        echo "Installing herdr launch agent ($herdr_label)"
        # Retire the brew services job; it would fight over the same socket.
        if [[ -f "$HOME/Library/LaunchAgents/sh.brew.herdr.plist" ]]; then
            brew services stop herdr
        fi
        launchctl bootout "gui/$UID/$herdr_label" 2>/dev/null
        mkdir -p "$HOME/Library/LaunchAgents" "$HOME/.config/herdr"
        print -r -- "$herdr_desired" > "$herdr_plist"
        launchctl bootstrap "gui/$UID" "$herdr_plist"
    elif ! launchctl print "gui/$UID/$herdr_label" >/dev/null 2>&1; then
        launchctl bootstrap "gui/$UID" "$herdr_plist"
    fi

    unset herdr_label herdr_plist herdr_wrapper herdr_log herdr_desired
fi
