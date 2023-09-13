local smartcolumn = {}

local config = {
   colorcolumn = "80",
   disabled_filetypes = { "help", "text", "markdown" },
   custom_colorcolumn = {},
   scope = "file",
}

-- merge values from t2 into t1. returns t1
local function table_merge(t1, t2)
    for _, v in ipairs(t2) do
        table.insert(t1, v)
    end
    return t1
end

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
   if column_len <= min_colorcolumn or wrapped_col_width - gutter_width <= min_colorcolumn then
       return t
   end
   local c_col = min_colorcolumn
   while c_col <= unwrapped_col_width do
       table.insert(t, c_col)
       c_col = c_col + wrapped_col_width - gutter_width
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
   local state_changed = (vim.b.prev_screen_width ~= win_width)
   vim.b.prev_screen_width = win_width

   for _, line in pairs(lines) do
      local success, column_number = pcall(vim.fn.strdisplaywidth, line)

      if not success then
         return false, {}
      end

      max_column = math.max(max_column, column_number)
      if vim.wo[win].wrap == true then
         local wrapped_rows = math.ceil(column_number / (win_width - gutter_width))
         if not state_changed then
             state_changed = (vim.b.prev_num_wrapped_rows ~= wrapped_rows)
             vim.b.prev_num_wrapped_rows = wrapped_rows
             vim.b.prev_screen_width = win_width
         end
         local unwrapped_col_width = wrapped_rows * (win_width - gutter_width)
         exceed_columns = get_wrapped_column_numbers(unwrapped_col_width,
            win_width, gutter_width, column_number, min_colorcolumn)
         exceed_table = table_merge(exceed_table, exceed_columns)
      else
          state_changed = state_changed or (vim.b.prev_num_wrapped_rows ~= 1)
          vim.b.prev_num_wrapped_rows = 1
      end
   end

   local does_exceed = (not vim.tbl_contains(config.disabled_filetypes, vim.bo.ft)) and max_column > min_colorcolumn


   local state = 0
   if does_exceed and state_changed then
      state = 3
   elseif does_exceed and vim.wo[win].wrap then
      state = 2
   elseif does_exceed then
      state = 1
      exceed_table = {min_colorcolumn}
   end

   return state, exceed_table
end

local function set_win_colorcolumns(buf, win, colorcolumns)
   local current_state
   local exceed_cols
   if type(colorcolumns) == "table" then
      local colorcolumns_to_set = {}
      local diff_state = nil
      for _, colorcolumn in ipairs(colorcolumns) do
         current_state, exceed_cols = exceed(buf, win, tonumber(colorcolumn))
         if current_state ~= vim.b.prev_state then
            diff_state = current_state
            colorcolumns_to_set = table_merge(colorcolumns_to_set, exceed_cols)
         end
      end
      if diff_state ~= nil then
         vim.wo[win].colorcolumn = table.concat(colorcolumns_to_set, ",")
         vim.b.prev_state = diff_state
      end
   elseif type(colorcolumns) == "string" then
       current_state, exceed_cols = exceed(buf, win, tonumber(colorcolumns))
       if current_state ~= vim.b.prev_state then
          vim.b.prev_state = current_state
          vim.wo[win].colorcolumn = table.concat(exceed_cols, ",")
       end
   else
       vim.wo[win].colorcolumn = nil
   end
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


   local current_buf = vim.api.nvim_get_current_buf()
   local wins = vim.api.nvim_list_wins()
   for _, win in pairs(wins) do
      local buf = vim.api.nvim_win_get_buf(win)
      if buf == current_buf then
          set_win_colorcolumns(buf, win, colorcolumns)
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
