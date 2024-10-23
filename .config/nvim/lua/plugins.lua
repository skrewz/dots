return {
  'airblade/vim-gitgutter',
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' }
  },
  'ggandor/leap.nvim',
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },
  'tomlion/vim-solidity',
  'rodjek/vim-puppet',
  'neovim/nvim-lspconfig',
  'airblade/vim-gitgutter',
  'airblade/vim-rooter',
  'tpope/vim-vinegar',
  'tpope/vim-commentary',
  'leafgarland/typescript-vim',
  'pangloss/vim-javascript',
  'rhysd/vim-grammarous',
  --'gerrard00/vim-mocha-only', { 'for': ['javascript'] },
  'mbbill/undotree',
  'm4xshen/hardtime.nvim',
  --'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' },
  'deoplete-plugins/deoplete-jedi',
  'deoplete-plugins/deoplete-dictionary',
  'beauwilliams/focus.nvim',
  'ludovicchabant/vim-gutentags',
  'salkin-mada/openscad.nvim',
  'saltstack/salt-vim',
  'nvim-lua/plenary.nvim',
  'kyazdani42/nvim-web-devicons',
  'hrsh7th/nvim-cmp',
  'hrsh7th/cmp-nvim-lsp',
  'hrsh7th/cmp-buffer',
  'hrsh7th/cmp-path',
  'hrsh7th/cmp-cmdline',
  'hrsh7th/nvim-cmp',
  'hrsh7th/cmp-vsnip',
  'hrsh7th/cmp-vsnip',
  'hrsh7th/vim-vsnip',
  {
    "Dynge/gitmoji.nvim",
    dependencies = {
      "hrsh7th/nvim-cmp",
    },
    opts = {},
    ft = "gitcommit",
  },
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      { "fredrikaverpil/neotest-golang", version = "*" }, -- Installation
    },
    keys = {
      {
        "<Leader>tf",
        function()
          require("neotest").run.run(vim.fn.expand("%"))
        end,
        desc = "Debug nearest test",
      },
    },
  },
  'kkharji/sqlite.lua',
  'nvim-telescope/telescope.nvim',
  'cljoly/telescope-repo.nvim',
  'nvim-telescope/telescope-frecency.nvim',
  'lervag/vimtex',
  'ray-x/go.nvim',
  -- {
  --   "jackMort/ChatGPT.nvim",
  --   event = "VeryLazy",
  --   config = function()
  --     require("chatgpt").setup({
	-- api_key_cmd = "sed -nre /^API_KEY/{s/^.*=//;p} " .. vim.fn.expand("$HOME") .. "/.chatgpt-cli",
  --     })
  --   end,
  --   dependencies = {
  --     "MunifTanjim/nui.nvim",
  --     "nvim-lua/plenary.nvim",
  --     "folke/trouble.nvim",
  --     "nvim-telescope/telescope.nvim"
  --   }
  -- }
  'marko-cerovac/material.nvim',
}
