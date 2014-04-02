vim-capmark
===========

Dashboard of capital mark

## Intro

CapMark is a vim plugin for browsing capital marks and let you handle capital mark more friendly.
You can add bookmark for each capital mark and quickveiw capital marks without jumping to it. 
CapMark let you easily gain the overview of capital marks and jump to desired mark precisely.
  
## Installation

Use pathogen to install capmark:

      cd ~/.vim/bundle
      git clone https://github.com/wecanspeak/vim-capmark.git
      
And don't forget go to doc directory, open capmark.txt with vim, then `:Helptags` to generate help doc.
     
## Usage

It is probably convenient to map hotkey to toggle CapMark window. Add this into .vimrc:
  
      nnoremap <F7> :CapmarkToggle<CR>
  
Then you can press <F7> to hide or show CapMark window.

## License

MIT Licensed. Copyright (c) Enzo Wang.
