{ ... }:
{
  programs.tmux = {
    enable = true;
    prefix = "C-a";
    mouse = true;
    keyMode = "vi";

    extraConfig = ''
      # Vim-style pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Easier splitting
      bind | split-window -h
      bind - split-window -v
      unbind '"'
      unbind %

      # Reload config
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

      # Vim copy mode
      setw -g mode-keys vi
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      # Status bar
      set -g status-position bottom
      set -g status-interval 5
      set -g status-justify left
      set -g status-style "bg=default,fg=default"
      set -g status-left-length 40
      set -g status-right-length 80

      # Palette colours match the Powerlevel10k prompt so both follow the terminal theme
      set -g status-left "#{?client_prefix,#[fg=colour0 bg=colour3 bold],#[fg=colour254 bg=colour4 bold]}  #S #[default] "
      set -g status-right "#[fg=default] %H:%M  #[fg=colour244] %d %b #[fg=colour254 bg=colour4 bold] 󰒋 #h "

      setw -g window-status-separator ""
      setw -g window-status-format "#[fg=colour244] #I #W#{?window_zoomed_flag, 󰊓,} "
      setw -g window-status-current-format "#[fg=colour4 bold] #I #W#{?window_zoomed_flag, 󰊓,} "
      setw -g window-status-activity-style "fg=colour3"

      set -g pane-border-style "fg=colour238"
      set -g pane-active-border-style "fg=colour4"
      set -g message-style "bg=default,fg=colour4,fill=terminal"
      set -g mode-style "bg=colour238,fg=default"
    '';
  };
}
