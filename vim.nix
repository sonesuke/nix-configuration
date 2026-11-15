{ pkgs, ... }:
{
  programs.vim = {
    enable = true;
    defaultEditor = true; # EDITOR / VISUAL = vim (git commit, etc.)

    plugins = with pkgs.vimPlugins; [
      vim-sensible # widely agreed defaults
      vim-nix # syntax for .nix files
      vim-commentary # gcc / gc{motion} to toggle comments
      vim-surround # cs"' , ysiw) ...
    ];

    settings = {
      number = true;
      relativenumber = false;
      expandtab = true;
      tabstop = 4;
      shiftwidth = 4;
      ignorecase = true;
      smartcase = true;
      mouse = "a";
      background = "dark";
      undofile = true;
      undodir = [ "$HOME/.local/state/vim/undo" ];
      directory = [ "$HOME/.local/state/vim/swap//" ];
    };

    extraConfig = ''
      set encoding=utf-8
      set fileencodings=utf-8,cp932,euc-jp,sjis
      set hlsearch
      set clipboard=unnamed
      set signcolumn=auto
      set scrolloff=5
      set list listchars=tab:»\ ,trail:·,nbsp:␣
      syntax on
      filetype plugin indent on

      " Esc clears search highlight
      nnoremap <silent> <Esc><Esc> :nohlsearch<CR>

      " Per-language indent
      autocmd FileType nix,yaml,json,javascript,typescript,html,css,lua setlocal shiftwidth=2 tabstop=2
      autocmd FileType make setlocal noexpandtab
    '';
  };

  # Ensure the undo/swap directories exist.
  home.file.".local/state/vim/undo/.keep".text = "";
  home.file.".local/state/vim/swap/.keep".text = "";
}
