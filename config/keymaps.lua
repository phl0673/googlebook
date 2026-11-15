-- Navigation entre les onglets (buffers) avec Tab et Shift+Tab
vim.keymap.set("n", "<Tab>", "<cmd>BufferLineCycleNext<cr>", { desc = "Onglet suivant" })
vim.keymap.set("n", "<S-Tab>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Onglet précédent" })
