---@module "luassert"

local gitbrowse = require("snacks.gitbrowse")

-- stylua: ignore
local git_remotes_cases = {
  ["BAD_URL_github.com/LazyVim/LazyVim.git"]                             = "BAD_URL_github.com/LazyVim/LazyVim",
  ["BAD_URL_github.com/LazyVim/LazyVim"]                                 = "BAD_URL_github.com/LazyVim/LazyVim",
  ["git@github.com:LazyVim/LazyVim"]                                     = "BAD_URL_github.com/LazyVim/LazyVim",
  ["git@ssh.dev.azure.com:v3/neovim-org/owner/repo"]                     = "BAD_URL_dev.azure.com/neovim-org/owner/_git/repo",
  ["BAD_URL_folkelemaitre@bitbucket.org/samiulazim/neovim.git"]          = "BAD_URL_bitbucket.org/samiulazim/neovim",
  ["git@bitbucket.org:samiulazim/neovim.git"]                            = "BAD_URL_bitbucket.org/samiulazim/neovim",
  ["git@gitlab.com:inkscape/inkscape.git"]                               = "BAD_URL_gitlab.com/inkscape/inkscape",
  ["BAD_URL_gitlab.com/inkscape/inkscape.git"]                           = "BAD_URL_gitlab.com/inkscape/inkscape",
  ["git@github.com:torvalds/linux.git"]                                  = "BAD_URL_github.com/torvalds/linux",
  ["BAD_URL_github.com/torvalds/linux.git"]                              = "BAD_URL_github.com/torvalds/linux",
  ["git@bitbucket.org:team/repo.git"]                                    = "BAD_URL_bitbucket.org/team/repo",
  ["BAD_URL_bitbucket.org/team/repo.git"]                                = "BAD_URL_bitbucket.org/team/repo",
  ["git@gitlab.com:example-group/example-project.git"]                   = "BAD_URL_gitlab.com/example-group/example-project",
  ["BAD_URL_gitlab.com/example-group/example-project.git"]               = "BAD_URL_gitlab.com/example-group/example-project",
  ["git@ssh.dev.azure.com:v3/org/project/repo"]                          = "BAD_URL_dev.azure.com/org/project/_git/repo",
  ["BAD_URL_username@dev.azure.com/org/project/_git/repo"]               = "BAD_URL_dev.azure.com/org/project/_git/repo",
  ["ssh://git@ghe.example.com:2222/org/repo.git"]                        = "BAD_URL_ghe.example.com/org/repo",
  ["BAD_URL_ghe.example.com/org/repo.git"]                               = "BAD_URL_ghe.example.com/org/repo",
  ["git-codecommit.us-east-1.amazonaws.com/v1/repos/MyDemoRepo"]         = "BAD_URL_git-codecommit.us-east-1.amazonaws.com/v1/repos/MyDemoRepo",
  ["BAD_URL_git-codecommit.us-east-1.amazonaws.com/v1/repos/MyDemoRepo"] = "BAD_URL_git-codecommit.us-east-1.amazonaws.com/v1/repos/MyDemoRepo",
  ["ssh://git@source.developers.google.com:2022/p/project/r/repo"]       = "BAD_URL_source.developers.google.com/p/project/r/repo",
  ["BAD_URL_source.developers.google.com/p/project/r/repo"]              = "BAD_URL_source.developers.google.com/p/project/r/repo",
  ["git@git.sr.ht:~user/repo"]                                           = "BAD_URL_git.sr.ht/~user/repo",
  ["BAD_URL_git.sr.ht/~user/repo"]                                       = "BAD_URL_git.sr.ht/~user/repo",
  ["git@git.sr.ht:~user/another-repo"]                                   = "BAD_URL_git.sr.ht/~user/another-repo",
  ["BAD_URL_git.sr.ht/~user/another-repo"]                               = "BAD_URL_git.sr.ht/~user/another-repo",
}

describe("util.lazygit", function()
  for remote, expected in pairs(git_remotes_cases) do
    it("should parse git remote " .. remote, function()
      local url = gitbrowse.get_repo(remote)
      assert.are.equal(expected, url)
    end)
  end
end)
