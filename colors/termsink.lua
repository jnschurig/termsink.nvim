package.loaded["termsink"] = nil
package.loaded["termsink.util"] = nil
package.loaded["termsink.colors"] = nil
package.loaded["termsink.colors.conditionals"] = nil
package.loaded["termsink.functions"] = nil
package.loaded["termsink.highlights"] = nil
package.loaded["termsink.highlights.plugins"] = nil
-- Lualine caches required theme modules; clear so re-sourcing this colorscheme
-- (e.g. after a terminal theme switch) picks up the freshly-derived palette
-- instead of the previous load's stale fg/bg values.
for k in pairs(package.loaded) do
  if k:match("^lualine%.themes%.termsink") then
    package.loaded[k] = nil
  end
end

require("termsink.util").load()
