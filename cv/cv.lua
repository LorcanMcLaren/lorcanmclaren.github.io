--[[
CV filter: write each CV entry once in Markdown; this renders it as styled
HTML (classes in styles.css) or as LaTeX for the PDF.

  Header      -> built from the `cv:` block in the front matter
  ::: {.cv-entry title="..." position="..." date="..."}   (title optional)
  ::: {.cv-rows}  containing a pipe table: date | detail [| amount]
      extra classes (e.g. .cv-presentations) are passed through to the HTML
  ::: {.cv-total label="..."}  prints the sum of the amount column of every
      cv-rows table in the document
  ::: {.cv-pubs}  one paragraph per publication
]]

local is_html = quarto.doc.is_format("html")
local is_pdf = quarto.doc.is_format("latex")

-- render Pandoc inlines/blocks to a string in the current output format
local function write(content, fmt)
  local blocks
  if pandoc.utils.type(content) == "Inlines" then
    blocks = { pandoc.Plain(content) }
  else
    blocks = content
  end
  local out = pandoc.write(pandoc.Pandoc(blocks), fmt or (is_html and "html" or "latex"))
  return (out:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- parse an attribute string as Markdown inlines
local function md(s)
  if s == nil or s == "" then return nil end
  local doc = pandoc.read(s, "markdown")
  if #doc.blocks == 0 then return nil end
  return doc.blocks[1].content
end

local function cell_inlines(cell)
  local blocks = cell.contents
  if #blocks == 0 then return pandoc.Inlines({}) end
  return pandoc.utils.blocks_to_inlines(blocks)
end

local function format_euro(n)
  local s = tostring(math.floor(n))
  s = s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
  return "€" .. s
end

---------------------------------------------------------------- header

local function header(meta)
  local cv = meta.cv
  if not cv then return nil end
  local name = cv.name and pandoc.Inlines(cv.name) or pandoc.Inlines({})
  local position = cv.position and pandoc.Inlines(cv.position)
  local affiliation = cv.affiliation and pandoc.Inlines(cv.affiliation)
  local links = {}
  for _, l in ipairs(cv.links or {}) do
    table.insert(links, write(pandoc.Inlines(l)))
  end

  if is_html then
    local h = { '<div class="cv-header">',
      '  <h1 class="cv-name">' .. write(name) .. '</h1>' }
    if position then table.insert(h, '  <p class="cv-position">' .. write(position) .. '</p>') end
    if affiliation then table.insert(h, '  <p class="cv-affiliation">' .. write(affiliation) .. '</p>') end
    if #links > 0 then
      table.insert(h, '  <p class="cv-links">' ..
        table.concat(links, ' <span class="cv-sep">|</span> ') .. '</p>')
    end
    if cv.pdf then
      table.insert(h, '  <p class="cv-download"><a href="' .. pandoc.utils.stringify(cv.pdf) ..
        '"><i class="fa-solid fa-download"></i> Download PDF</a></p>')
    end
    table.insert(h, '</div>')
    return pandoc.RawBlock("html", table.concat(h, "\n"))
  elseif is_pdf then
    local h = { "\\begin{center}", "{\\LARGE \\textbf{" .. write(name) .. "}}\\\\[0.3em]" }
    if position then table.insert(h, "{\\normalsize " .. write(position) .. "}\\\\[0.2em]") end
    if affiliation then table.insert(h, "{\\small\\itshape " .. write(affiliation) .. "}\\\\[0.3em]") end
    if #links > 0 then table.insert(h, "{\\small " .. table.concat(links, " | ") .. "}") end
    table.insert(h, "\\end{center}")
    table.insert(h, "\\vspace{0.5em}\n\\hrule\n\\vspace{0.5em}")
    return pandoc.RawBlock("latex", table.concat(h, "\n"))
  end
end

---------------------------------------------------------------- entries

local function entry(div)
  local title = md(div.attributes.title)
  local position = md(div.attributes.position)
  local date = md(div.attributes.date)

  if is_html then
    local h = { '<div class="cv-entry">', '  <div class="cv-entry-header">',
      '    <div class="cv-entry-left">' }
    local left = {}
    if title then table.insert(left, '      <span class="cv-entry-title">' .. write(title) .. '</span>') end
    if position then table.insert(left, '      <span class="cv-entry-position">' .. write(position) .. '</span>') end
    table.insert(h, table.concat(left, "<br>\n"))
    table.insert(h, '    </div>')
    table.insert(h, '    <div class="cv-entry-right">')
    if date then table.insert(h, '      <span class="cv-entry-date">' .. write(date) .. '</span>') end
    table.insert(h, '    </div>')
    table.insert(h, '  </div>')
    if #div.content > 0 then
      local body = write(div.content):gsub("<ul>", '<ul class="cv-items">')
      table.insert(h, body)
    end
    table.insert(h, '</div>')
    return pandoc.RawBlock("html", table.concat(h, "\n"))
  elseif is_pdf then
    local line = pandoc.Inlines({})
    local hfill = pandoc.RawInline("latex", "\\hfill ")
    if title then
      line:insert(pandoc.Strong(title))
      if date then line:insert(hfill); line:extend(date) end
      if position then line:insert(pandoc.LineBreak()); line:insert(pandoc.Emph(position)) end
    else
      if position then line:insert(pandoc.Emph(position)) end
      if date then line:insert(hfill); line:extend(date) end
    end
    local blocks = pandoc.Blocks({ pandoc.Para(line) })
    blocks:extend(div.content)
    return blocks
  end
end

---------------------------------------------------------------- rows

local function rows(div)
  local tbl
  for _, b in ipairs(div.content) do
    if b.t == "Table" then tbl = b; break end
  end
  if not tbl then return nil end

  local data = {}
  for _, body in ipairs(tbl.bodies) do
    for _, row in ipairs(body.body) do
      local cells = {}
      for _, c in ipairs(row.cells) do table.insert(cells, cell_inlines(c)) end
      table.insert(data, cells)
    end
  end

  local ncols = #tbl.colspecs

  if is_html then
    local h = {}
    local classes = { "cv-honors" }
    for _, c in ipairs(div.classes) do
      if c ~= "cv-rows" then table.insert(classes, c) end
    end
    table.insert(h, '<div class="' .. table.concat(classes, " ") .. '">')
    for _, r in ipairs(data) do
      table.insert(h, '  <div class="cv-honor-row">')
      table.insert(h, '    <span class="cv-honor-date">' .. write(r[1] or {}) .. '</span>')
      table.insert(h, '    <span class="cv-honor-detail">' .. write(r[2] or {}) .. '</span>')
      if ncols >= 3 then
        table.insert(h, '    <span class="cv-honor-amount">' .. write(r[3] or {}) .. '</span>')
      end
      table.insert(h, '  </div>')
    end
    table.insert(h, '</div>')
    return pandoc.RawBlock("html", table.concat(h, "\n"))
  elseif is_pdf then
    local h = {}
    local spec = ncols >= 3 and "@{}lXr@{}" or "@{}lX@{}"
    table.insert(h, "\\noindent\\begin{tabularx}{\\textwidth}{" .. spec .. "}")
    for i, r in ipairs(data) do
      local cells = {}
      for j = 1, ncols do table.insert(cells, write(r[j] or pandoc.Inlines({}))) end
      local sep = i < #data and " \\\\[0.4em]" or " \\\\"
      table.insert(h, table.concat(cells, " & ") .. sep)
    end
    table.insert(h, "\\end{tabularx}")
    return pandoc.RawBlock("latex", table.concat(h, "\n"))
  end
end

---------------------------------------------------------------- publications

local function pubs(div)
  if is_html then
    local h = { '<div class="cv-pubs">' }
    for _, b in ipairs(div.content) do
      if b.t == "Para" or b.t == "Plain" then
        table.insert(h, '  <p class="cv-pub">' .. write(b.content) .. '</p>')
      end
    end
    table.insert(h, '</div>')
    return pandoc.RawBlock("html", table.concat(h, "\n"))
  elseif is_pdf then
    local out = pandoc.Blocks({})
    for _, b in ipairs(div.content) do
      if b.t == "Para" or b.t == "Plain" then
        local inl = pandoc.Inlines({ pandoc.RawInline("latex", "\\hangindent=0.7cm ") })
        inl:extend(b.content)
        out:insert(pandoc.Para(inl))
      end
    end
    return out
  end
end

---------------------------------------------------------------- funding total

local function amount_total(doc)
  local sum = 0
  doc:walk({
    Div = function(div)
      if not div.classes:includes("cv-rows") then return nil end
      for _, b in ipairs(div.content) do
        if b.t == "Table" and #b.colspecs >= 3 then
          for _, body in ipairs(b.bodies) do
            for _, row in ipairs(body.body) do
              local c = row.cells[3]
              if c then
                local digits = pandoc.utils.stringify(c.contents):gsub("[^%d]", "")
                sum = sum + (tonumber(digits) or 0)
              end
            end
          end
        end
      end
    end,
  })
  return sum
end

local function total_block(div, sum)
  local label = div.attributes.label or "Total"
  if is_html then
    return pandoc.RawBlock("html", '<p class="cv-funding-total">' .. label ..
      ': <strong>' .. format_euro(sum) .. '</strong></p>')
  elseif is_pdf then
    return pandoc.RawBlock("latex", "\\begin{center}\n\\textit{" .. label .. ": " ..
      format_euro(sum) .. "}\n\\end{center}")
  end
end

---------------------------------------------------------------- dispatch

return {
  {
    Pandoc = function(doc)
      local sum = amount_total(doc)
      doc = doc:walk({
        Div = function(div)
          if div.classes:includes("cv-total") then return total_block(div, sum) end
          if div.classes:includes("cv-entry") then return entry(div) end
          if div.classes:includes("cv-rows") then return rows(div) end
          if div.classes:includes("cv-pubs") then return pubs(div) end
        end,
      })
      local h = header(doc.meta)
      if h then doc.blocks:insert(1, h) end
      return doc
    end,
  },
}
