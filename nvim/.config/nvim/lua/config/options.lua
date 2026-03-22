local opt = vim.opt

-- Line numbers
opt.number = true              -- Show line numbers
opt.relativenumber = true      -- Relative line numbers (great for jumps like 5j)

-- Tabs & indentation
opt.tabstop = 2                -- Visual width of a tab character
opt.shiftwidth = 2             -- Width for auto-indent
opt.expandtab = true           -- Use spaces instead of tabs
opt.smartindent = true         -- Smart auto-indenting

-- Search
opt.ignorecase = true          -- Case-insensitive search...
opt.smartcase = true           -- ...unless you use uppercase
opt.hlsearch = false           -- Don't persist search highlight
opt.incsearch = true           -- Show matches as you type

-- Appearance
opt.termguicolors = true       -- True color support
opt.signcolumn = "yes"         -- Always show sign column (prevents text shift)
opt.cursorline = true          -- Highlight current line
opt.scrolloff = 8              -- Keep 8 lines above/below cursor
opt.sidescrolloff = 8          -- Keep 8 columns left/right of cursor
opt.wrap = false               -- No line wrapping

-- Splits
opt.splitright = true          -- New vertical splits open to the right
opt.splitbelow = true          -- New horizontal splits open below

-- System
opt.clipboard = "unnamedplus"  -- Use system clipboard by default
opt.undofile = true            -- Persistent undo (survives closing file)
opt.swapfile = false           -- No swap files
opt.updatetime = 250           -- Faster CursorHold events
opt.timeoutlen = 300           -- Faster key sequence completion

-- Completion
opt.completeopt = "menuone,noselect"