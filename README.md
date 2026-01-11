## tmux requirements (important)

Your tmux must allow OSC passthrough.

Add to `~/.tmux.conf`:

```tmux
```
set -g allow-passthrough on
```
```

(Recent tmux versions default this to safe behavior.)
