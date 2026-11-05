-- Small non-executing JSON decoder for Open-Meteo responses. Lua 5.1 compatible.
-- Arrays preserve JSON null slots with a sentinel, avoiding shifted forecasts.
local M={null={}}
local function utf8(n)
    if n<128 then return string.char(n) end
    if n<2048 then return string.char(192+math.floor(n/64),128+n%64) end
    if n<65536 then return string.char(224+math.floor(n/4096),128+math.floor(n/64)%64,128+n%64) end
    return string.char(240+math.floor(n/262144),128+math.floor(n/4096)%64,128+math.floor(n/64)%64,128+n%64)
end
function M.decode(s)
    local p,depth=1,0
    local function fail() error('Invalid JSON at byte '..p) end
    local function ws() local _,e=s:find('^[ \r\n\t]*',p); p=(e or p-1)+1 end
    local function str()
        p=p+1; local parts={}
        while p<=#s do
            local c=s:sub(p,p); p=p+1
            if c=='"' then return table.concat(parts) end
            if c=='\\' then
                c=s:sub(p,p); p=p+1
                local esc={['"']='"',['\\']='\\',['/']='/',b='\b',f='\f',n='\n',r='\r',t='\t'}
                if c=='u' then
                    local h=s:sub(p,p+3); if not h:match('^%x%x%x%x$') then fail() end
                    local n=tonumber(h,16); p=p+4
                    if n>=0xD800 and n<=0xDBFF then
                        if s:sub(p,p+1)~='\\u' then fail() end
                        local tail=s:sub(p+2,p+5); if not tail:match('^%x%x%x%x$') then fail() end
                        local lo=tonumber(tail,16); if lo<0xDC00 or lo>0xDFFF then fail() end
                        n=0x10000+(n-0xD800)*1024+(lo-0xDC00); p=p+6
                    elseif n>=0xDC00 and n<=0xDFFF then fail() end
                    parts[#parts+1]=utf8(n)
                elseif esc[c] then parts[#parts+1]=esc[c] else fail() end
            else
                if c:byte()<32 then fail() end
                parts[#parts+1]=c
            end
        end
        fail()
    end
    local value
    value=function()
        ws(); depth=depth+1; if depth>64 then fail() end
        local c=s:sub(p,p); local result
        if c=='"' then result=str()
        elseif c=='{' or c=='[' then
            local object=c=='{'; local close=object and '}' or ']'
            result={}; p=p+1; ws()
            if s:sub(p,p)~=close then
                while true do
                    local key
                    if object then
                        if s:sub(p,p)~='"' then fail() end
                        key=str(); ws(); if s:sub(p,p)~=':' then fail() end; p=p+1
                    else key=#result+1 end
                    result[key]=value(); ws()
                    if s:sub(p,p)==close then break end
                    if s:sub(p,p)~=',' then fail() end
                    p=p+1; ws()
                end
            end
            p=p+1
        elseif s:sub(p,p+3)=='null' then result=M.null; p=p+4
        elseif s:sub(p,p+3)=='true' then result=true; p=p+4
        elseif s:sub(p,p+4)=='false' then result=false; p=p+5
        else
            local token=s:match('^%-?%d+%.?%d*[eE][+-]?%d+',p) or s:match('^%-?%d+%.%d+',p) or s:match('^%-?%d+',p)
            if not token or token:match('^%-?0%d') then fail() end
            result=tonumber(token); if not result or result==math.huge or result==-math.huge then fail() end
            p=p+#token
        end
        depth=depth-1; return result
    end
    local result=value(); ws(); if p<=#s then fail() end
    return result
end
return M
