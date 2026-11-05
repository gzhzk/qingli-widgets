-- Merge-safe first-run setup. Only missing package-local appearance/settings
-- files are created. Credentials are never opened, created, or migrated here.
local M = {}
local names = {'Settings', 'Accent', 'Material'}
local function state(path)
    local f,err,code=io.open(path,'rb')
    if f then f:close();return 'exists' end
    if code==2 then return 'missing' end
    return 'error'
end
local function read(path)
    local f=io.open(path,'rb')
    if not f then return nil end
    local data=f:read(131073);f:close()
    if not data or #data==0 or #data>131072 then return nil end
    return data
end
function M.ensure(resources,storage)
    local pending={}
    for _,name in ipairs(names) do
        local path=resources..name..'.inc'
        local current=state(path)
        if current=='error' then return false,'Cannot read existing '..name..'.inc; left untouched.' end
        if current=='missing' then
            local backup=state(path..'.bak')
            if backup=='error' then return false,'Cannot read existing backup; left untouched.' end
            if backup=='exists' then
                if not storage.recover(path) or state(path)~='exists' then
                    return false,'Cannot restore existing '..name..'.inc backup.'
                end
            else
                local data=read(resources..name..'.defaults.inc')
                if not data then return false,'Missing or unreadable '..name..'.defaults.inc.' end
                pending[#pending+1]={path=path,data=data,name=name}
            end
        end
    end
    for _,item in ipairs(pending) do
        -- Recheck immediately before writing: never replace a newly appearing file.
        if state(item.path)~='missing' then return false,'Settings changed during initialization; retry.' end
        if not storage.write(item.path,item.data) then return false,'Cannot create missing '..item.name..'.inc.' end
    end
    return true,#pending
end
function M.scale(resources,fallback)
    local data=read(resources..'Settings.inc')
    if not data then return fallback end
    if data:sub(1,2)=='\255\254' then
        local out={}
        for i=3,#data-1,2 do
            local low,high=data:byte(i,i+1)
            out[#out+1]=(high==0 and low<128) and string.char(low) or '?'
        end
        data=table.concat(out)
    end
    local section=''
    for line in data:gmatch('[^\r\n]+') do
        local name=line:match('^%s*%[([^%]]+)%]%s*$')
        if name then section=name:lower() end
        if section=='variables' then
            local key,value=line:match('^%s*([%w_]+)%s*=%s*(.-)%s*$')
            if key and key:lower()=='scale' then
                local n=tonumber(value)
                if n and n==n and n>0 and n<10000 then return n end
                return fallback
            end
        end
    end
    return fallback
end
return M
