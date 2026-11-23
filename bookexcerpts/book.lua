--[[
    Information about the book that is currently open.
]]

local Book = {}

-- { title = ..., author = ..., chapter = ... } (strings, possibly empty)
function Book.info(ui)
    local props = ui.doc_props or {}
    local file = ui.document and ui.document.file or ""
    local title = props.display_title or props.title
    if not title or title == "" then
        title = file:match("([^/]+)%.[^.]+$") or file
    end
    local author = props.authors or ""
    author = author:gsub("\n", ", ")

    local chapter = ""
    if ui.toc and ui.toc.getTocTitleOfCurrentPage then
        local ok, c = pcall(ui.toc.getTocTitleOfCurrentPage, ui.toc)
        if ok and c then chapter = c end
    end
    return { title = title, author = author, chapter = chapter }
end

-- Cover as a BlitBuffer, or nil if the book has none. The caller owns the
-- buffer and must :free() it.
function Book.cover(ui)
    local bb
    pcall(function()
        bb = ui.bookinfo:getCoverImage(ui.document)
    end)
    return bb
end

return Book
