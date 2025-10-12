" Name:         wallbash
" Description:  wallbash template
" Author:       The HyDE Project
" License:      Same as Vim
" Last Change:  April 2025

if exists('g:loaded_wallbash') | finish | endif
let g:loaded_wallbash = 1


" Detect background based on terminal colors
if $BACKGROUND =~# 'light'
  set background=light
else
  set background=dark
endif

" hi clear
let g:colors_name = 'wallbash'

let s:t_Co = &t_Co

" Terminal color setup
if (has('termguicolors') && &termguicolors) || has('gui_running')
  let s:is_dark = &background == 'dark'

  " Define terminal colors based on the background
  if s:is_dark
    let g:terminal_ansi_colors = ['333130', 'A39765', 'C2927A', 'C2B17A',
                                \ 'A38765', 'E6D49A', 'E6B39A', '101011',
                                \ '5C564F', 'C2B47A', 'E6B39A', 'F0DFAA',
                                \ 'C2A17A', 'F0DFAA', 'F0C1AA', 'FFFFFF']
  else
    " Lighter colors for light theme
    let g:terminal_ansi_colors = ['FFFFFF', 'E6D79A', 'F0C1AA', 'F0DFAA',
                                \ 'E6C39A', 'FFF3CC', 'FFDDCC', 'A7A089',
                                \ '101011', 'F0E2AA', 'FFDDCC', 'FFF3CC',
                                \ 'F0D0AA', 'FFF3CC', 'FFDDCC', '333130']
  endif

  " Nvim uses g:terminal_color_{0-15} instead
  for i in range(g:terminal_ansi_colors->len())
    let g:terminal_color_{i} = g:terminal_ansi_colors[i]
  endfor
endif

      " For Neovim compatibility
      if has('nvim')
        " Set Neovim specific terminal colors
        let g:terminal_color_0 = '#' . g:terminal_ansi_colors[0]
        let g:terminal_color_1 = '#' . g:terminal_ansi_colors[1]
        let g:terminal_color_2 = '#' . g:terminal_ansi_colors[2]
        let g:terminal_color_3 = '#' . g:terminal_ansi_colors[3]
        let g:terminal_color_4 = '#' . g:terminal_ansi_colors[4]
        let g:terminal_color_5 = '#' . g:terminal_ansi_colors[5]
        let g:terminal_color_6 = '#' . g:terminal_ansi_colors[6]
        let g:terminal_color_7 = '#' . g:terminal_ansi_colors[7]
        let g:terminal_color_8 = '#' . g:terminal_ansi_colors[8]
        let g:terminal_color_9 = '#' . g:terminal_ansi_colors[9]
        let g:terminal_color_10 = '#' . g:terminal_ansi_colors[10]
        let g:terminal_color_11 = '#' . g:terminal_ansi_colors[11]
        let g:terminal_color_12 = '#' . g:terminal_ansi_colors[12]
        let g:terminal_color_13 = '#' . g:terminal_ansi_colors[13]
        let g:terminal_color_14 = '#' . g:terminal_ansi_colors[14]
        let g:terminal_color_15 = '#' . g:terminal_ansi_colors[15]
      endif

" Function to dynamically invert colors for UI elements
function! s:inverse_color(color)
  " This function takes a hex color (without #) and returns its inverse
  " Convert hex to decimal values
  let r = str2nr(a:color[0:1], 16)
  let g = str2nr(a:color[2:3], 16)
  let b = str2nr(a:color[4:5], 16)

  " Calculate inverse (255 - value)
  let r_inv = 255 - r
  let g_inv = 255 - g
  let b_inv = 255 - b

  " Convert back to hex
  return printf('%02x%02x%02x', r_inv, g_inv, b_inv)
endfunction

" Function to be called for selection background
function! InverseSelectionBg()
  if &background == 'dark'
    return 'FFDDCC'
  else
    return '523F29'
  endif
endfunction

" Add high-contrast dynamic selection highlighting using the inverse color function
augroup WallbashDynamicHighlight
  autocmd!
  " Update selection highlight when wallbash colors change
  autocmd ColorScheme wallbash call s:update_dynamic_highlights()
augroup END

function! s:update_dynamic_highlights()
  let l:bg_color = synIDattr(synIDtrans(hlID('Normal')), 'bg#')
  if l:bg_color != ''
    let l:bg_color = l:bg_color[1:] " Remove # from hex color
    let l:inverse = s:inverse_color(l:bg_color)

    " Apply inverse color to selection highlights
    execute 'highlight! CursorSelection guifg=' . l:bg_color . ' guibg=#' . l:inverse

    " Link dynamic highlights to various selection groups
    highlight! link NeoTreeCursorLine CursorSelection
    highlight! link TelescopeSelection CursorSelection
    highlight! link CmpItemSelected CursorSelection
    highlight! link PmenuSel CursorSelection
    highlight! link WinSeparator VertSplit
  endif
endfunction

" Make selection visible right away for current colorscheme
call s:update_dynamic_highlights()

" Conditional highlighting based on background
if &background == 'dark'
  " Base UI elements with transparent backgrounds
  hi Normal guibg=NONE guifg=#FFFFFF gui=NONE cterm=NONE
  hi Pmenu guibg=#A7A089 guifg=#FFFFFF gui=NONE cterm=NONE
  hi StatusLine guifg=#FFFFFF guibg=#A7A089 gui=NONE cterm=NONE
  hi StatusLineNC guifg=#FFFFFF guibg=#5C564F gui=NONE cterm=NONE
  hi VertSplit guifg=#A37A65 guibg=NONE gui=NONE cterm=NONE
  hi LineNr guifg=#A37A65 guibg=NONE gui=NONE cterm=NONE
  hi SignColumn guifg=NONE guibg=NONE gui=NONE cterm=NONE
  hi FoldColumn guifg=#FFFFFF guibg=NONE gui=NONE cterm=NONE

  " NeoTree with transparent background including unfocused state
  hi NeoTreeNormal guibg=NONE guifg=#FFFFFF gui=NONE cterm=NONE
  hi NeoTreeEndOfBuffer guibg=NONE guifg=#FFFFFF gui=NONE cterm=NONE
  hi NeoTreeFloatNormal guibg=NONE guifg=#FFFFFF gui=NONE cterm=NONE
  hi NeoTreeFloatBorder guifg=#A37A65 guibg=NONE gui=NONE cterm=NONE
  hi NeoTreeWinSeparator guifg=#5C564F guibg=NONE gui=NONE cterm=NONE

  " NeoTree with transparent background
  hi NeoTreeNormal guibg=NONE guifg=#FFFFFF gui=NONE cterm=NONE
  hi NeoTreeEndOfBuffer guibg=NONE guifg=#FFFFFF gui=NONE cterm=NONE
  hi NeoTreeRootName guifg=#FFDDCC guibg=NONE gui=bold cterm=bold

  " TabLine highlighting with complementary accents
  hi TabLine guifg=#FFFFFF guibg=#A7A089 gui=NONE cterm=NONE
  hi TabLineFill guifg=NONE guibg=NONE gui=NONE cterm=NONE
  hi TabLineSel guifg=#333130 guibg=#FFDDCC gui=bold cterm=bold
  hi TabLineSeparator guifg=#A37A65 guibg=#A7A089 gui=NONE cterm=NONE

  " Interactive elements with dynamic contrast
  hi Search guifg=#5C564F guibg=#F0C1AA gui=NONE cterm=NONE
  hi Visual guifg=#5C564F guibg=#E6B39A gui=NONE cterm=NONE
  hi MatchParen guifg=#5C564F guibg=#FFDDCC gui=bold cterm=bold

  " Menu item hover highlight
  hi CmpItemAbbrMatch guifg=#FFDDCC guibg=NONE gui=bold cterm=bold
  hi CmpItemAbbrMatchFuzzy guifg=#F0C1AA guibg=NONE gui=bold cterm=bold
  hi CmpItemMenu guifg=#FFFFFF guibg=NONE gui=italic cterm=italic
  hi CmpItemAbbr guifg=#FFFFFF guibg=NONE gui=NONE cterm=NONE
  hi CmpItemAbbrDeprecated guifg=#101011 guibg=NONE gui=strikethrough cterm=strikethrough

  " Specific menu highlight groups
  hi WhichKey guifg=#FFDDCC guibg=NONE gui=NONE cterm=NONE
  hi WhichKeySeparator guifg=#101011 guibg=NONE gui=NONE cterm=NONE
  hi WhichKeyGroup guifg=#E6B39A guibg=NONE gui=NONE cterm=NONE
  hi WhichKeyDesc guifg=#F0C1AA guibg=NONE gui=NONE cterm=NONE
  hi WhichKeyFloat guibg=#5C564F guifg=NONE gui=NONE cterm=NONE

  " Selection and hover highlights with inverted colors
  hi CursorColumn guifg=NONE guibg=#A7A089 gui=NONE cterm=NONE
  hi Cursor guibg=#FFFFFF guifg=#333130 gui=NONE cterm=NONE
  hi lCursor guibg=#FFFFFF guifg=#333130 gui=NONE cterm=NONE
  hi CursorIM guibg=#FFFFFF guifg=#333130 gui=NONE cterm=NONE
  hi TermCursor guibg=#FFFFFF guifg=#333130 gui=NONE cterm=NONE
  hi TermCursorNC guibg=#FFFFFF guifg=#333130 gui=NONE cterm=NONE
  hi CursorLine guibg=NONE ctermbg=NONE gui=underline cterm=underline
  hi CursorLineNr guifg=#FFDDCC guibg=NONE gui=bold cterm=bold

  hi QuickFixLine guifg=#5C564F guibg=#E6B39A gui=NONE cterm=NONE
  hi IncSearch guifg=#5C564F guibg=#FFDDCC gui=NONE cterm=NONE
  hi NormalNC guibg=#5C564F guifg=#FFFFFF gui=NONE cterm=NONE
  hi Directory guifg=#F0C1AA guibg=NONE gui=NONE cterm=NONE
  hi WildMenu guifg=#5C564F guibg=#FFDDCC gui=bold cterm=bold

  " Add highlight groups for focused items with inverted colors
  hi CursorLineFold guifg=#FFDDCC guibg=#5C564F gui=NONE cterm=NONE
  hi FoldColumn guifg=#FFFFFF guibg=NONE gui=NONE cterm=NONE
  hi Folded guifg=#FFFFFF guibg=#A7A089 gui=italic cterm=italic

  " File explorer specific highlights
  hi NeoTreeNormal guibg=NONE guifg=#FFFFFF gui=NONE cterm=NONE
  hi NeoTreeEndOfBuffer guibg=NONE guifg=#FFFFFF gui=NONE cterm=NONE
  hi NeoTreeRootName guifg=#FFDDCC guibg=NONE gui=bold cterm=bold
  hi NeoTreeFileName guifg=#FFFFFF guibg=NONE gui=NONE cterm=NONE
  hi NeoTreeFileIcon guifg=#F0C1AA guibg=NONE gui=NONE cterm=NONE
  hi NeoTreeDirectoryName guifg=#F0C1AA guibg=NONE gui=NONE cterm=NONE
  hi NeoTreeDirectoryIcon guifg=#F0C1AA guibg=NONE gui=NONE cterm=NONE
  hi NeoTreeGitModified guifg=#E6B39A guibg=NONE gui=NONE cterm=NONE
  hi NeoTreeGitAdded guifg=#C2927A guibg=NONE gui=NONE cterm=NONE
  hi NeoTreeGitDeleted guifg=#A39765 guibg=NONE gui=NONE cterm=NONE
  hi NeoTreeGitUntracked guifg=#C2B17A guibg=NONE gui=NONE cterm=NONE
  hi NeoTreeIndentMarker guifg=#8F6A57 guibg=NONE gui=NONE cterm=NONE
  hi NeoTreeSymbolicLinkTarget guifg=#E6B39A guibg=NONE gui=NONE cterm=NONE

  " File explorer cursor highlights with strong contrast
  " hi NeoTreeCursorLine guibg=#E6B39A guifg=#333130 gui=bold cterm=bold
  " hi! link NeoTreeCursor NeoTreeCursorLine
  " hi! link NeoTreeCursorLineSign NeoTreeCursorLine

  " Use wallbash colors for explorer snack in dark mode
  hi WinBar guifg=#FFFFFF guibg=#A7A089 gui=bold cterm=bold
  hi WinBarNC guifg=#FFFFFF guibg=#5C564F gui=NONE cterm=NONE
  hi ExplorerSnack guibg=#FFDDCC guifg=#333130 gui=bold cterm=bold
  hi BufferTabpageFill guibg=#333130 guifg=#101011 gui=NONE cterm=NONE
  hi BufferCurrent guifg=#FFFFFF guibg=#FFDDCC gui=bold cterm=bold
  hi BufferCurrentMod guifg=#FFFFFF guibg=#E6B39A gui=bold cterm=bold
  hi BufferCurrentSign guifg=#FFDDCC guibg=#5C564F gui=NONE cterm=NONE
  hi BufferVisible guifg=#FFFFFF guibg=#A7A089 gui=NONE cterm=NONE
  hi BufferVisibleMod guifg=#FFFFFF guibg=#A7A089 gui=NONE cterm=NONE
  hi BufferVisibleSign guifg=#E6B39A guibg=#5C564F gui=NONE cterm=NONE
  hi BufferInactive guifg=#101011 guibg=#5C564F gui=NONE cterm=NONE
  hi BufferInactiveMod guifg=#A37A65 guibg=#5C564F gui=NONE cterm=NONE
  hi BufferInactiveSign guifg=#A37A65 guibg=#5C564F gui=NONE cterm=NONE

  " Fix link colors to make them more visible
  hi link Hyperlink NONE
  hi link markdownLinkText NONE
  hi Underlined guifg=#FF00FF guibg=NONE gui=bold,underline cterm=bold,underline
  hi Special guifg=#FF00FF guibg=NONE gui=bold cterm=bold
  hi markdownUrl guifg=#FF00FF guibg=NONE gui=underline cterm=underline
  hi markdownLinkText guifg=#FF00FF guibg=NONE gui=bold cterm=bold
  hi htmlLink guifg=#FF00FF guibg=NONE gui=bold,underline cterm=bold,underline

  " Add more direct highlights for badges in markdown
  hi markdownH1 guifg=#FF00FF guibg=NONE gui=bold cterm=bold
  hi markdownLinkDelimiter guifg=#FF00FF guibg=NONE gui=bold cterm=bold
  hi markdownLinkTextDelimiter guifg=#FF00FF guibg=NONE gui=bold cterm=bold
  hi markdownIdDeclaration guifg=#FF00FF guibg=NONE gui=bold cterm=bold
else
  " Light theme with transparent backgrounds
  hi Normal guibg=NONE guifg=#333130 gui=NONE cterm=NONE
  hi Pmenu guibg=#101011 guifg=#333130 gui=NONE cterm=NONE
  hi StatusLine guifg=#FFFFFF guibg=#7D714B gui=NONE cterm=NONE
  hi StatusLineNC guifg=#333130 guibg=#FFFFFF gui=NONE cterm=NONE
  hi VertSplit guifg=#7D714B guibg=NONE gui=NONE cterm=NONE
  hi LineNr guifg=#7D714B guibg=NONE gui=NONE cterm=NONE
  hi SignColumn guifg=NONE guibg=NONE gui=NONE cterm=NONE
  hi FoldColumn guifg=#5C564F guibg=NONE gui=NONE cterm=NONE

  " NeoTree with transparent background including unfocused state
  hi NeoTreeNormal guibg=NONE guifg=#333130 gui=NONE cterm=NONE
  hi NeoTreeEndOfBuffer guibg=NONE guifg=#333130 gui=NONE cterm=NONE
  hi NeoTreeFloatNormal guibg=NONE guifg=#333130 gui=NONE cterm=NONE
  hi NeoTreeFloatBorder guifg=#7D664B guibg=NONE gui=NONE cterm=NONE
  hi NeoTreeWinSeparator guifg=#FFFFFF guibg=NONE gui=NONE cterm=NONE

  " NeoTree with transparent background
  hi NeoTreeNormal guibg=NONE guifg=#333130 gui=NONE cterm=NONE
  hi NeoTreeEndOfBuffer guibg=NONE guifg=#333130 gui=NONE cterm=NONE
  hi NeoTreeRootName guifg=#523F29 guibg=NONE gui=bold cterm=bold

  " TabLine highlighting with complementary accents
  hi TabLine guifg=#333130 guibg=#FFFFFF gui=NONE cterm=NONE
  hi TabLineFill guifg=NONE guibg=NONE gui=NONE cterm=NONE
  hi TabLineSel guifg=#FFFFFF guibg=#523F29 gui=bold cterm=bold
  hi TabLineSeparator guifg=#7D714B guibg=#FFFFFF gui=NONE cterm=NONE

  " Interactive elements with complementary contrast
  hi Search guifg=#FFFFFF guibg=#6B543A gui=NONE cterm=NONE
  hi Visual guifg=#FFFFFF guibg=#7D714B gui=NONE cterm=NONE
  hi MatchParen guifg=#FFFFFF guibg=#523F29 gui=bold cterm=bold

  " Menu item hover highlight
  hi CmpItemAbbrMatch guifg=#523F29 guibg=NONE gui=bold cterm=bold
  hi CmpItemAbbrMatchFuzzy guifg=#6B543A guibg=NONE gui=bold cterm=bold
  hi CmpItemMenu guifg=#5C564F guibg=NONE gui=italic cterm=italic
  hi CmpItemAbbr guifg=#333130 guibg=NONE gui=NONE cterm=NONE
  hi CmpItemAbbrDeprecated guifg=#A7A089 guibg=NONE gui=strikethrough cterm=strikethrough

  " Specific menu highlight groups
  hi WhichKey guifg=#523F29 guibg=NONE gui=NONE cterm=NONE
  hi WhichKeySeparator guifg=#A7A089 guibg=NONE gui=NONE cterm=NONE
  hi WhichKeyGroup guifg=#7D664B guibg=NONE gui=NONE cterm=NONE
  hi WhichKeyDesc guifg=#6B543A guibg=NONE gui=NONE cterm=NONE
  hi WhichKeyFloat guibg=#FFFFFF guifg=NONE gui=NONE cterm=NONE

  " Selection and hover highlights with inverted colors
  hi CursorColumn guifg=NONE guibg=#101011 gui=NONE cterm=NONE
  hi Cursor guibg=#333130 guifg=#FFFFFF gui=NONE cterm=NONE
  hi lCursor guibg=#FFFFFF guifg=#333130 gui=NONE cterm=NONE
  hi CursorIM guibg=#FFFFFF guifg=#333130 gui=NONE cterm=NONE
  hi TermCursor guibg=#333130 guifg=#FFFFFF gui=NONE cterm=NONE
  hi TermCursorNC guibg=#FFFFFF guifg=#333130 gui=NONE cterm=NONE
  hi CursorLine guibg=NONE ctermbg=NONE gui=underline cterm=underline
  hi CursorLineNr guifg=#523F29 guibg=NONE gui=bold cterm=bold

  hi QuickFixLine guifg=#FFFFFF guibg=#6B543A gui=NONE cterm=NONE
  hi IncSearch guifg=#FFFFFF guibg=#523F29 gui=NONE cterm=NONE
  hi NormalNC guibg=#FFFFFF guifg=#5C564F gui=NONE cterm=NONE
  hi Directory guifg=#523F29 guibg=NONE gui=NONE cterm=NONE
  hi WildMenu guifg=#FFFFFF guibg=#523F29 gui=bold cterm=bold

  " Add highlight groups for focused items with inverted colors
  hi CursorLineFold guifg=#523F29 guibg=#FFFFFF gui=NONE cterm=NONE
  hi FoldColumn guifg=#5C564F guibg=NONE gui=NONE cterm=NONE
  hi Folded guifg=#333130 guibg=#101011 gui=italic cterm=italic

  " File explorer specific highlights
  hi NeoTreeNormal guibg=NONE guifg=#333130 gui=NONE cterm=NONE
  hi NeoTreeEndOfBuffer guibg=NONE guifg=#333130 gui=NONE cterm=NONE
  hi NeoTreeRootName guifg=#523F29 guibg=NONE gui=bold cterm=bold
  hi NeoTreeFileName guifg=#333130 guibg=NONE gui=NONE cterm=NONE
  hi NeoTreeFileIcon guifg=#6B543A guibg=NONE gui=NONE cterm=NONE
  hi NeoTreeDirectoryName guifg=#6B543A guibg=NONE gui=NONE cterm=NONE
  hi NeoTreeDirectoryIcon guifg=#6B543A guibg=NONE gui=NONE cterm=NONE
  hi NeoTreeGitModified guifg=#7D664B guibg=NONE gui=NONE cterm=NONE
  hi NeoTreeGitAdded guifg=#8F8257 guibg=NONE gui=NONE cterm=NONE
  hi NeoTreeGitDeleted guifg=#A39765 guibg=NONE gui=NONE cterm=NONE
  hi NeoTreeGitUntracked guifg=#C2B17A guibg=NONE gui=NONE cterm=NONE
  hi NeoTreeIndentMarker guifg=#8F7557 guibg=NONE gui=NONE cterm=NONE
  hi NeoTreeSymbolicLinkTarget guifg=#7D664B guibg=NONE gui=NONE cterm=NONE

  " File explorer cursor highlights with strong contrast
  " hi NeoTreeCursorLine guibg=#6B543A guifg=#FFFFFF gui=bold cterm=bold
  " hi! link NeoTreeCursor NeoTreeCursorLine
  " hi! link NeoTreeCursorLineSign NeoTreeCursorLine

  " Use wallbash colors for explorer snack in light mode
  hi WinBar guifg=#333130 guibg=#101011 gui=bold cterm=bold
  hi WinBarNC guifg=#5C564F guibg=#FFFFFF gui=NONE cterm=NONE
  hi ExplorerSnack guibg=#523F29 guifg=#FFFFFF gui=bold cterm=bold
  hi BufferTabpageFill guibg=#FFFFFF guifg=#A7A089 gui=NONE cterm=NONE
  hi BufferCurrent guifg=#FFFFFF guibg=#523F29 gui=bold cterm=bold
  hi BufferCurrentMod guifg=#FFFFFF guibg=#7D664B gui=bold cterm=bold
  hi BufferCurrentSign guifg=#523F29 guibg=#FFFFFF gui=NONE cterm=NONE
  hi BufferVisible guifg=#333130 guibg=#101011 gui=NONE cterm=NONE
  hi BufferVisibleMod guifg=#5C564F guibg=#101011 gui=NONE cterm=NONE
  hi BufferVisibleSign guifg=#7D664B guibg=#FFFFFF gui=NONE cterm=NONE
  hi BufferInactive guifg=#A7A089 guibg=#FFFFFF gui=NONE cterm=NONE
  hi BufferInactiveMod guifg=#A38765 guibg=#FFFFFF gui=NONE cterm=NONE
  hi BufferInactiveSign guifg=#A38765 guibg=#FFFFFF gui=NONE cterm=NONE

  " Fix link colors to make them more visible
  hi link Hyperlink NONE
  hi link markdownLinkText NONE
  hi Underlined guifg=#FF00FF guibg=NONE gui=bold,underline cterm=bold,underline
  hi Special guifg=#FF00FF guibg=NONE gui=bold cterm=bold
  hi markdownUrl guifg=#FF00FF guibg=NONE gui=underline cterm=underline
  hi markdownLinkText guifg=#FF00FF guibg=NONE gui=bold cterm=bold
  hi htmlLink guifg=#FF00FF guibg=NONE gui=bold,underline cterm=bold,underline

  " Add more direct highlights for badges in markdown
  hi markdownH1 guifg=#FF00FF guibg=NONE gui=bold cterm=bold
  hi markdownLinkDelimiter guifg=#FF00FF guibg=NONE gui=bold cterm=bold
  hi markdownLinkTextDelimiter guifg=#FF00FF guibg=NONE gui=bold cterm=bold
  hi markdownIdDeclaration guifg=#FF00FF guibg=NONE gui=bold cterm=bold
endif

" UI elements that are the same in both themes with transparent backgrounds
hi NormalFloat guibg=NONE guifg=NONE gui=NONE cterm=NONE
hi FloatBorder guifg=#7D714B guibg=NONE gui=NONE cterm=NONE
hi SignColumn guifg=NONE guibg=NONE gui=NONE cterm=NONE
hi DiffAdd guifg=#FFFFFF guibg=#C2927A gui=NONE cterm=NONE
hi DiffChange guifg=#FFFFFF guibg=#A39565 gui=NONE cterm=NONE
hi DiffDelete guifg=#FFFFFF guibg=#A39765 gui=NONE cterm=NONE
hi TabLineFill guifg=NONE guibg=NONE gui=NONE cterm=NONE

" Fix selection highlighting with proper color derivatives
hi TelescopeSelection guibg=#FFF3CC guifg=#333130 gui=bold cterm=bold
hi TelescopeSelectionCaret guifg=#FFFFFF guibg=#FFF3CC gui=bold cterm=bold
hi TelescopeMultiSelection guibg=#E6D49A guifg=#333130 gui=bold cterm=bold
hi TelescopeMatching guifg=#C2B47A guibg=NONE gui=bold cterm=bold

" Minimal fix for explorer selection highlighting
hi NeoTreeCursorLine guibg=#FFF3CC guifg=#333130 gui=bold

" Fix for LazyVim menu selection highlighting
hi Visual guibg=#FFF5CC guifg=#333130 gui=bold
hi CursorLine guibg=NONE ctermbg=NONE gui=underline cterm=underline
hi PmenuSel guibg=#FFF5CC guifg=#333130 gui=bold
hi WildMenu guibg=#FFF5CC guifg=#333130 gui=bold

" Create improved autocommands to ensure highlighting persists with NeoTree focus fixes
augroup WallbashSelectionFix
  autocmd!
  " Force these persistent highlights with transparent backgrounds where possible
  autocmd ColorScheme * if &background == 'dark' |
    \ hi Normal guibg=NONE |
    \ hi NeoTreeNormal guibg=NONE |
    \ hi SignColumn guibg=NONE |
    \ hi NormalFloat guibg=NONE |
    \ hi FloatBorder guibg=NONE |
    \ hi TabLineFill guibg=NONE |
    \ else |
    \ hi Normal guibg=NONE |
    \ hi NeoTreeNormal guibg=NONE |
    \ hi SignColumn guibg=NONE |
    \ hi NormalFloat guibg=NONE |
    \ hi FloatBorder guibg=NONE |
    \ hi TabLineFill guibg=NONE |
    \ endif

  " Force NeoTree background to be transparent even when unfocused
  autocmd WinEnter,WinLeave,BufEnter,BufLeave * if &ft == 'neo-tree' || &ft == 'NvimTree' |
    \ hi NeoTreeNormal guibg=NONE |
    \ hi NeoTreeEndOfBuffer guibg=NONE |
    \ endif

  " Fix NeoTree unfocus issue specifically in LazyVim
  autocmd VimEnter,ColorScheme * hi link NeoTreeNormalNC NeoTreeNormal

  " Make CursorLine less obtrusive by using underline instead of background
  autocmd ColorScheme * hi CursorLine guibg=NONE ctermbg=NONE gui=underline cterm=underline

  " Make links visible across modes
  autocmd ColorScheme * if &background == 'dark' |
    \ hi Underlined guifg=#FF00FF guibg=NONE gui=bold,underline cterm=bold,underline |
    \ hi Special guifg=#FF00FF guibg=NONE gui=bold cterm=bold |
    \ else |
    \ hi Underlined guifg=#FF00FF guibg=NONE gui=bold,underline cterm=bold,underline |
    \ hi Special guifg=#FF00FF guibg=NONE gui=bold cterm=bold |
    \ endif

  " Fix markdown links specifically
  autocmd FileType markdown hi markdownUrl guifg=#FF00FF guibg=NONE gui=underline,bold
  autocmd FileType markdown hi markdownLinkText guifg=#FF00FF guibg=NONE gui=bold
  autocmd FileType markdown hi markdownIdDeclaration guifg=#FF00FF guibg=NONE gui=bold
  autocmd FileType markdown hi htmlLink guifg=#FF00FF guibg=NONE gui=bold,underline
augroup END

" Create a more aggressive fix for NeoTree background in LazyVim
augroup FixNeoTreeBackground
  autocmd!
  " Force NONE background for NeoTree at various points to override tokyonight fallback
  autocmd ColorScheme,VimEnter,WinEnter,BufEnter * hi NeoTreeNormal guibg=NONE guifg=#FFFFFF ctermbg=NONE
  autocmd ColorScheme,VimEnter,WinEnter,BufEnter * hi NeoTreeNormalNC guibg=NONE guifg=#FFFFFF ctermbg=NONE
  autocmd ColorScheme,VimEnter,WinEnter,BufEnter * hi NeoTreeEndOfBuffer guibg=NONE guifg=#FFFFFF ctermbg=NONE

  " Also fix NvimTree for NvChad
  autocmd ColorScheme,VimEnter,WinEnter,BufEnter * hi NvimTreeNormal guibg=NONE guifg=#FFFFFF ctermbg=NONE
  autocmd ColorScheme,VimEnter,WinEnter,BufEnter * hi NvimTreeNormalNC guibg=NONE guifg=#FFFFFF ctermbg=NONE
  autocmd ColorScheme,VimEnter,WinEnter,BufEnter * hi NvimTreeEndOfBuffer guibg=NONE guifg=#FFFFFF ctermbg=NONE

  " Apply highlight based on current theme
  autocmd ColorScheme,VimEnter * if &background == 'dark' |
    \ hi NeoTreeCursorLine guibg=#FFF3CC guifg=#333130 gui=bold cterm=bold |
    \ hi NvimTreeCursorLine guibg=#FFF3CC guifg=#333130 gui=bold cterm=bold |
    \ else |
    \ hi NeoTreeCursorLine guibg=#523F29 guifg=#FFFFFF gui=bold cterm=bold |
    \ hi NvimTreeCursorLine guibg=#523F29 guifg=#FFFFFF gui=bold cterm=bold |
    \ endif

  " Force execution after other plugins have loaded
  autocmd VimEnter * doautocmd ColorScheme
augroup END

" Add custom autocommand specifically for LazyVim markdown links
augroup LazyVimMarkdownFix
  autocmd!
  " Force link visibility in LazyVim with stronger override
  autocmd FileType markdown,markdown.mdx,markdown.gfm hi! def link markdownUrl MagentaLink
  autocmd FileType markdown,markdown.mdx,markdown.gfm hi! def link markdownLinkText MagentaLink
  autocmd FileType markdown,markdown.mdx,markdown.gfm hi! def link markdownLink MagentaLink
  autocmd FileType markdown,markdown.mdx,markdown.gfm hi! def link markdownLinkDelimiter MagentaLink
  autocmd FileType markdown,markdown.mdx,markdown.gfm hi! MagentaLink guifg=#FF00FF gui=bold,underline

  " Apply when LazyVim is detected
  autocmd User LazyVimStarted doautocmd FileType markdown
  autocmd VimEnter * if exists('g:loaded_lazy') | doautocmd FileType markdown | endif
augroup END

" Add custom autocommand specifically for markdown files with links
augroup MarkdownLinkFix
  autocmd!
  " Use bright hardcoded magenta that will definitely be visible
  autocmd FileType markdown hi markdownUrl guifg=#FF00FF guibg=NONE gui=underline,bold
  autocmd FileType markdown hi markdownLinkText guifg=#FF00FF guibg=NONE gui=bold
  autocmd FileType markdown hi markdownIdDeclaration guifg=#FF00FF guibg=NONE gui=bold
  autocmd FileType markdown hi htmlLink guifg=#FF00FF guibg=NONE gui=bold,underline

  " Force these highlights right after vim loads
  autocmd VimEnter * if &ft == 'markdown' | doautocmd FileType markdown | endif
augroup END

" Remove possibly conflicting previous autocommands
augroup LazyVimFix
  autocmd!
augroup END

augroup MinimalExplorerFix
  autocmd!
augroup END
