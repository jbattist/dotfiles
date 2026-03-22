local map = vim.keymap.set

-- ── Escape ──────────────────────────────────────────────
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- ── File operations ─────────────────────────────────────
map("n", "<leader>w", ":w<CR>", { desc = "Save file" })
map("n", "<leader>q", ":q<CR>", { desc = "Quit" })
map("n", "<leader>Q", ":qa!<CR>", { desc = "Quit ALL panels" })
map("n", "<leader>x", ":x<CR>", { desc = "Save and quit" })

-- ── Window navigation ───────────────────────────────────
map("n", "<C-h>", "<C-w>h", { desc = "Move to left split" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to lower split" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to upper split" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right split" })

-- ── Resize splits ───────────────────────────────────────
map("n", "<C-Up>", ":resize +2<CR>", { desc = "Increase height" })
map("n", "<C-Down>", ":resize -2<CR>", { desc = "Decrease height" })
map("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Decrease width" })
map("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Increase width" })

-- ── Buffers ─────────────────────────────────────────────
map("n", "<S-l>", ":bnext<CR>", { desc = "Next buffer" })
map("n", "<S-h>", ":bprevious<CR>", { desc = "Previous buffer" })
map("n", "<leader>bd", ":bdelete<CR>", { desc = "Close buffer" })
map("n", "<leader>bp", ":BufferLinePick<CR>", { desc = "Pick buffer by letter" })
map("n", "<leader>bc", ":BufferLinePickClose<CR>", { desc = "Pick buffer to close" })

-- ── Visual mode ─────────────────────────────────────────
map("v", "<", "<gv", { desc = "Indent left (stay selected)" })
map("v", ">", ">gv", { desc = "Indent right (stay selected)" })
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- ── File explorer ───────────────────────────────────────
map("n", "<leader>e", ":Neotree toggle<CR>", { desc = "Toggle file explorer" })
map("n", "<leader>o", ":Neotree focus<CR>", { desc = "Focus file explorer" })

-- ── Telescope (find stuff) ──────────────────────────────
map("n", "<leader>ff", function() require("telescope.builtin").find_files() end, { desc = "Find files" })
map("n", "<leader>fg", function() require("telescope.builtin").live_grep() end, { desc = "Live grep (search text)" })
map("n", "<leader>fb", function() require("telescope.builtin").buffers() end, { desc = "Find open buffers" })
map("n", "<leader>fh", function() require("telescope.builtin").help_tags() end, { desc = "Search help docs" })
map("n", "<leader>fr", function() require("telescope.builtin").oldfiles() end, { desc = "Recent files" })
map("n", "<leader>fs", function() require("telescope.builtin").grep_string() end, { desc = "Grep word under cursor" })
map("n", "<leader>ft", ":TodoTelescope<CR>", { desc = "Find TODOs" })

-- ── Theme ───────────────────────────────────────────────
map("n", "<leader>T", function()
  require("telescope.builtin").colorscheme({ enable_preview = true })
end, { desc = "Switch colorscheme" })

-- ── Terminal ────────────────────────────────────────────
local bottom_term = nil
local opencode_term = nil
local lazygit_term = nil

map("n", "<leader>tt", function()
  if not bottom_term then
    bottom_term = require("toggleterm.terminal").Terminal:new({
      direction = "horizontal",
      count = 5,
    })
  end
  bottom_term:toggle()
end, { desc = "Toggle bottom terminal" })

map("n", "<leader>to", function()
  if not opencode_term then
    opencode_term = require("toggleterm.terminal").Terminal:new({
      cmd = "opencode",
      direction = "vertical",
      count = 6,
    })
  end
  opencode_term:toggle()
end, { desc = "Toggle opencode (right)" })

-- ── Git ─────────────────────────────────────────────────
map("n", "<leader>gg", function()
  if not lazygit_term then
    lazygit_term = require("toggleterm.terminal").Terminal:new({
      cmd = "lazygit",
      direction = "float",
      float_opts = {
        border = "curved",
        width = function() return math.floor(vim.o.columns * 0.9) end,
        height = function() return math.floor(vim.o.lines * 0.9) end,
      },
      on_open = function() vim.cmd("startinsert!") end,
    })
  end
  lazygit_term:toggle()
end, { desc = "Lazygit" })

-- Terminal mode (inside a terminal)
map("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })
map("t", "<C-h>", [[<C-\><C-n><C-w>h]], { desc = "Move to left split" })
map("t", "<C-j>", [[<C-\><C-n><C-w>j]], { desc = "Move to lower split" })
map("t", "<C-k>", [[<C-\><C-n><C-w>k]], { desc = "Move to upper split" })
map("t", "<C-l>", [[<C-\><C-n><C-w>l]], { desc = "Move to right split" })

-- ── Trouble / Diagnostics ───────────────────────────────
map("n", "<leader>xx", ":Trouble diagnostics toggle<CR>", { desc = "All diagnostics" })
map("n", "<leader>xd", ":Trouble diagnostics toggle filter.buf=0<CR>", { desc = "This file's diagnostics" })

-- ── Layout ──────────────────────────────────────────────
map("n", "<leader>L", ":Layout<CR>", { desc = "Launch VS Code layout" })