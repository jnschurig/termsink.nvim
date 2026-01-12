#!/bin/sh
# POSIX terminal color query helper
# Emits raw rgb:RRRR/GGGG/BBBB values

exec 3</dev/tty 4>/dev/tty

ESC="$(printf '\033')"
ST="${ESC}\\"

osc() {
  if [ -n "$TMUX" ]; then
    printf '%sPtmux;%s%s%s' "$ESC" "$ESC" "$1" "$ST" >&4
  else
    printf '%s%s' "$ESC" "$1" >&4
  fi
}

# UI queries
osc "]10;?"
osc "]11;?"
osc "]12;?"
osc "]17;?"
osc "]18;?"
osc "]19;?"

# Palette queries
i=0
while [ "$i" -lt 16 ]; do
  osc "]4;$i;?"
  i=$((i + 1))
done

# Read replies briefly and normalize
timeout 0.25 awk '
/\]1[0-9];rgb:/ {
  match($0, /\]([0-9]+);(rgb:[0-9a-fA-F\/]+)/, m)
  code = m[1]
  rgb  = m[2]

  if (code == 10) print "ui.foreground=" rgb
  else if (code == 11) print "ui.background=" rgb
  else if (code == 12) print "ui.cursor_color=" rgb
  else if (code == 17) print "ui.selection_background=" rgb
  else if (code == 18) print "ui.cursor_text=" rgb
  else if (code == 19) print "ui.selection_foreground=" rgb
}

/\]4;[0-9]+;rgb:/ {
  match($0, /\]4;([0-9]+);(rgb:[0-9a-fA-F\/]+)/, m)
  print "palette." m[1] "=" m[2]
}
' <&3
