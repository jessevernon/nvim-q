" Title:        nvim-SQL
" Description:  A plugin to provide a way to query SQL from Neovim.
" Last Change:  Oct 2022
" Maintainer:   Example User <https://github.com/example-user>
"
" Prevents the plugin from being loaded multiple times. If the loaded
" variable exists, do nothing more. Otherwise, assign the loaded
" variable and continue running this instance of the plugin.
if exists("g:loaded_nvim_sql")
    finish
endif
let g:loaded_nvim_sql = 1

" Exposes the plugin's functions for use as commands in Neovim.
command! -range=% -nargs=* Sql lua require("nvim-sql").sql_parse_args(<line1>, <line2>, <q-args>)
