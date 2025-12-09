return {
  "christoomey/vim-tmux-navigator",
  lazy = false, -- 1. 立即加载，确保插件启动
  keys = { -- 2. 显式定义按键，强制覆盖 LazyVim 的默认设置
    { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
    { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
    { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
    { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
    { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
  },
}
