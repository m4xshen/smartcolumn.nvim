local smartcolumn = {}

local config = {
   colorcolumn = "80",
   disabled_filetypes = { "help", "text", "markdown" },
   custom_colorcolumn = {},
   scope = "file",
}

local function exceed(buf, win, min_colorcolumn)
   local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true) -- file scope
   if config.scope == "line" then
      lines = vim.api.nvim_buf_get_lines(
         buf,
         vim.fn.line(".", win) - 1,
         vim.fn.line(".", win),
         true
      )
   elseif config.scope == "window" then
      lines = vim.api.nvim_buf_get_lines(
         buf,
         vim.fn.line("w0", win) - 1,
         vim.fn.line("w$", win),
         true
      )
   end

   local max_column = 0

   for _, line in pairs(lines) do
      local success, column_number = pcall(vim.fn.strdisplaywidth, line)

      if not success then
         return false
      end

      max_column = math.max(max_column, column_number)
   end

   return not vim.tbl_contains(config.disabled_filetypes, vim.bo.ft)
      and max_column > min_colorcolumn
end

local function update()
   local buf_filetype = vim.api.nvim_buf_get_option(0, "filetype")
   local colorcolumns

   if type(config.custom_colorcolumn) == "function" then
      colorcolumns = config.custom_colorcolumn()
   else
      colorcolumns = config.custom_colorcolumn[buf_filetype]
         or config.colorcolumn
   end

   local min_colorcolumn = colorcolumns
   if type(colorcolumns) == "table" then
      min_colorcolumn = colorcolumns[1]
      for _, colorcolumn in pairs(colorcolumns) do
         min_colorcolumn = math.min(min_colorcolumn, colorcolumn)
      end
   end
   min_colorcolumn = tonumber(min_colorcolumn)

   local current_buf = vim.api.nvim_get_current_buf()
   local wins = vim.api.nvim_list_wins()
   for _, win in pairs(wins) do
      local buf = vim.api.nvim_win_get_buf(win)
      if buf == current_buf then
         local current_state = exceed(buf, win, min_colorcolumn)
         if current_state ~= vim.b.prev_state then
            vim.b.prev_state = current_state
            if current_state then
               if type(colorcolumns) == "table" then
                  vim.wo[win].colorcolumn = table.concat(colorcolumns, ",")
               else
                  vim.wo[win].colorcolumn = colorcolumns
               end
            else
               vim.wo[win].colorcolumn = ""
            end
         end
      end
   end
end

function smartcolumn.setup(user_config)
   user_config = user_config or {}

   for option, value in pairs(user_config) do
      config[option] = value
   end

   local group = vim.api.nvim_create_augroup("SmartColumn", {})
   vim.api.nvim_create_autocmd(
      { "BufEnter", "CursorMoved", "CursorMovedI", "WinScrolled" },
      {
         group = group,
         callback = update,
      }
   )
end

return smartcolumn
