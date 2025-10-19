{
  pkgs,
  config,
  ...
}:
# stolen from https://github.com/dmarcoux/dotfiles
{
  home.packages = [ pkgs.tlrc ];
  xdg.configFile."tlrc/config.toml".text = ''
    [cache]
    dir = "${config.xdg.cacheHome}/tlrc"
    mirror = "https://github.com/tldr-pages/tldr/releases/latest/download"
    auto_update = true
    max_age = 336
    languages = ["en", "tr", "ja"]

    [output]
    show_title = false
    platform_title = false
    show_hyphens = false
    example_prefix = "- "
    compact = true
    raw_markdown = false

    [indent]
    title = 2
    description = 2
    bullet = 2
    example = 4

    [style.title]
    color = "magenta"
    background = "default"
    bold = true
    underline = false
    italic = false
    dim = false
    strikethrough = false

    [style.description]
    color = "magenta"
    background = "default"
    bold = false
    underline = false
    italic = false
    dim = false
    strikethrough = false

    [style.bullet]
    color = "green"
    background = "default"
    bold = false
    underline = false
    italic = false
    dim = false
    strikethrough = false

    [style.example]
    color = "cyan"
    background = "default"
    bold = false
    underline = false
    italic = false
    dim = false
    strikethrough = false

    [style.url]
    color = "red"
    background = "default"
    bold = false
    underline = false
    italic = true
    dim = false
    strikethrough = false

    [style.inline_code]
    color = "yellow"
    background = "default"
    bold = false
    underline = false
    italic = true
    dim = false
    strikethrough = false

    [style.placeholder]
    color = "red"
    background = "default"
    bold = false
    underline = false
    italic = true
    dim = false
    strikethrough = false
  '';
}
