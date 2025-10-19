{
  programs.bash = {
    enable = true;
    bashrcExtra = ''
      if [ "dumb" == "$TERM" ] ; then
        export TERM=xterm-256color
      fi
    '';
  };
}
