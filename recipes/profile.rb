file '/root/.bashrc' do
  owner 'root'
  group 'root'
  mode '0400'
  content <<~BASH
    # ~/.bashrc: executed by bash(1) for non-login shells.

    # You may uncomment the following lines if you want `ls' to be colorized:
    export LS_OPTIONS='--color=auto'
    eval "`dircolors`"
    alias ls='ls $LS_OPTIONS'
    alias ll='ls $LS_OPTIONS -l'
    alias l='ls $LS_OPTIONS -lA'

    # Some more alias to avoid making mistakes:
    alias rm='rm -i'
    alias cp='cp -i'
    alias mv='mv -i'

    # Some more aliases for the sysadmin:
    alias sc='systemctl'
    alias jc='journalctl'
    alias kernel-follow='dmesg -dwT'
    alias vim='vim -p'
  BASH
end
