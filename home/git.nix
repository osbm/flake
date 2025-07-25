{
  programs.git = {
    enable = true;
    userEmail = "osbm@osbm.dev";
    userName = "osbm";
    signing = {
      format = "openpgp";
    };
    ignores = [
      "*.pyc" # python
      "*.swp" # vim
      "__pycache__" # python
      ".DS_Store" # macOS
      "result" # nix
      "node_modules" # node
    ];
    extraConfig = {
      credential = {
        helper = "store";
      };
      core = {
        editor = "vim";
        pager = "cat";
      };
      diff = {
        wsErrorHighlight = "all";
      };
      init = {
        defaultBranch = "main";
      };
      http = {
        postBuffer = 1048576000;
      };
      https = {
        postBuffer = 1048576000;
      };
      push = {
        autoSetupRemote = true;
      };
      filter.lfs = {
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
        process = "git-lfs filter-process";
        required = true;
      };
      signing = {
        signByDefault = true;
        key = "3A264839184185CF";
      };
    };
  };
}
