package 'tmux'

file '/etc/tmux.conf' do
  owner 'root'
  group 'root'
  mode '0444'
  content <<~CONF
    # Use `tmux source-file /etc/tmux.conf` to reload this config

    set -g prefix '`'
    set -g visual-activity on
    setw -g monitor-activity on
    setw -g window-status-current-style bg=red
  CONF
end
