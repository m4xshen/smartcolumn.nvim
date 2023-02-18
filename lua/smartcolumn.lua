local smartcolumn = {}

local config = {
   colorcolumn = 80,
   disabled_filetypes = { "help", "text", "markdown" },
}

local function is_disabled()
   local current_filetype = vim.api.nvim_buf_get_option(0, "filetype")
   for _, filetype in pairs(config.disabled_filetypes) do
      if filetype == current_filetype then
         return true
      end
   end
   return false
end

local function detect()
   local max_column = 0
   local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
   for _, line in pairs(lines) do
      max_column = math.max(max_column, vim.fn.strdisplaywidth(line))
   end

   local value = ""
   if not is_disabled() and max_column >= config.colorcolumn then
      value = tostring(config.colorcolumn)
   end

   local current_buf = vim.api.nvim_get_current_buf()
   local windows = vim.api.nvim_list_wins()
   for _, window in pairs(windows) do
      if vim.api.nvim_win_get_buf(window) == current_buf then
         vim.api.nvim_win_set_option(window, "colorcolumn", value)
      end
   end
end

function smartcolumn.setup(user_config)
   user_config = user_config or {}

   for option, value in pairs(user_config) do
      config[option] = value
   end

   vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI" },
      { callback = detect })
end

return smartcolumn
