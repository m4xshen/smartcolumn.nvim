local smartcolumn = {}

local config = {
   colorcolumn = "80",
   disabled_filetypes = { "help", "text", "markdown" },
   custom_colorcolumn = {},
   scope = "file",
}

-- this function returns the multiples of `column_len` that are less than
-- `unwrapped_col_width` mod the `wrapped_col_width`, minus the gutter width
-- returns a table containing the multiples of `column_len`
local function get_wrapped_column_numbers(unwrapped_col_width,
   wrapped_col_width,
   gutter_width,
   column_len,
   min_colorcolumn
   )
   local t = {}
   if column_len <= min_colorcolumn then
       return t
   end
   local c_col = min_colorcolumn
   while c_col <= unwrapped_col_width do
       table.insert(t, c_col)
       c_col = c_col + wrapped_col_width - gutter_width * math.floor(column_len / wrapped_col_width)
   end
   return t
end

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

   local exceed_table = {}
   local exceed_columns = {}
   local win_width = vim.api.nvim_win_get_width(win)
   local gutter_width = vim.fn.getwininfo(win)[1].textoff


   for _, line in pairs(lines) do
      local success, column_number = pcall(vim.fn.strdisplaywidth, line)

      if not success then
         return false
      end

      max_column = math.max(max_column, column_number)
      if vim.wo[win].wrap == true then
         local wrapped_rows = math.ceil(column_number / win_width)
         local unwrapped_col_width = wrapped_rows * column_number
         exceed_columns = get_wrapped_column_numbers(unwrapped_col_width,
            win_width, gutter_width, column_number, min_colorcolumn)
         exceed_table = vim.tbl_extend("keep", exceed_table, exceed_columns)
      end
   end

   local does_exceed = (not vim.tbl_contains(config.disabled_filetypes, vim.bo.ft)) and max_column > min_colorcolumn


   local state = 0
   if does_exceed and vim.wo[win].wrap then
      state = 2
   elseif does_exceed then
      state = 1
   end

   return state, exceed_table
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
         local current_state, exceed_cols = exceed(buf, win, min_colorcolumn)
         if current_state ~= vim.b.prev_state then
            vim.b.prev_state = current_state
            if current_state == 2 then
               if type(colorcolumns) == "table" then
                  colorcolumns = vim.tbl_extend("keep", colorcolumns, exceed_cols)
                  vim.wo[win].colorcolumn = table.concat(colorcolumns, ",")
               else
                  for _, v in ipairs(exceed_cols) do
                     colorcolumns = colorcolumns .. (",%d"):format(v)
                  end
                  vim.wo[win].colorcolumn = colorcolumns
                  print(colorcolumns)
               end
            elseif current_state == 1 then
               if type(colorcolumns) == "table" then
                  vim.wo[win].colorcolumn = table.concat(colorcolumns, ",")
               else
                  vim.wo[win].colorcolumn = colorcolumns
               end
            else
               vim.wo[win].colorcolumn = nil
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
