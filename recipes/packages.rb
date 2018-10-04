include_recipe 'sanity::htop'
include_recipe 'sanity::tmux'
include_recipe 'sanity::vim'

package %w(curl sudo)
