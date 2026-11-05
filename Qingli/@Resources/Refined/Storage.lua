-- Fixed package-local callers only. No shell, external programs, or Windows APIs.
-- Windows rename cannot replace an existing file. Keep one checked backup and
-- recover a missing primary on next load; this is not a power-loss transaction.
local M = {}
local function exists(path)
    local f = io.open(path, 'rb')
    if not f then return false end
    f:close()
    return true
end
function M.recover(path)
    if exists(path) or not exists(path .. '.bak') then return false end
    return os.rename(path .. '.bak', path) and true or false
end
function M.write(path, data)
    local tmp, backup = path .. '.tmp', path .. '.bak'
    -- Recover first, so a previous interrupted swap cannot discard the old file.
    M.recover(path)
    local f, err = io.open(tmp, 'wb')
    if not f then return false, err or 'cannot open temporary file' end
    local wrote, writeErr = f:write(data)
    local closed, closeErr = f:close()
    if not wrote or not closed then
        os.remove(tmp)
        return false, writeErr or closeErr or 'incomplete write'
    end
    local moved = false
    if exists(path) then
        if exists(backup) then
            local removed, removeErr = os.remove(backup)
            if not removed then os.remove(tmp); return false, removeErr end
        end
        local renamed, renameErr = os.rename(path, backup)
        if not renamed then os.remove(tmp); return false, renameErr end
        moved = true
    elseif exists(backup) then
        -- An unreadable/unrecoverable primary must not overwrite its backup.
        os.remove(tmp)
        return false, 'previous backup could not be recovered'
    end
    local installed, installErr = os.rename(tmp, path)
    if not installed then
        if moved then os.rename(backup, path) end
        os.remove(tmp)
        return false, installErr or 'cannot replace primary; backup retained'
    end
    return true
end
return M
