-- QWeather city REST adapter. Credentials stay in QWeather.local.json only.
-- A fixed Windows helper handles gzip; no SDK, global network changes, or
-- cross-provider fallback. Only validated coordinates enter helper arguments.
local M = {}
local function number(n) return type(n)=='number' and n==n and math.abs(n)<10000 end
local function safeText(s)
    if type(s)~='string' or #s==0 or #s>120 then return nil end
    return s:gsub('[%z\1-\31#%[%]]','')
end
local function ordinal(y,m,d)
    local leap=y%4==0 and (y%100~=0 or y%400==0)
    local lengths={31,leap and 29 or 28,31,30,31,30,31,31,30,31,30,31}
    if y<1970 or y>2200 or m<1 or m>12 or d<1 or d>lengths[m] then return nil end
    local offsets={0,31,59,90,120,151,181,212,243,273,304,334}
    local p=y-1
    return 365*p+math.floor(p/4)-math.floor(p/100)+math.floor(p/400)+offsets[m]+d+((leap and m>2) and 1 or 0)
end
-- Parse actual ISO offsets instead of interpreting the location's time as PC time.
local function timestamp(s)
    if type(s)~='string' then return nil end
    local y,m,d,h,n,tail=s:match('^(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d)(.*)$')
    if not y then return nil end
    local sec=0
    if tail:sub(1,1)==':' then
        local seconds,rest=tail:match('^:(%d%d)(.*)$')
        if not seconds then return nil end
        sec=tonumber(seconds);tail=rest
    end
    local offset=0
    if tail~='Z' then
        local sign,oh,om=tail:match('^([+-])(%d%d):(%d%d)$')
        if not sign or tonumber(oh)>14 or tonumber(om)>59 or (tonumber(oh)==14 and tonumber(om)~=0) then return nil end
        offset=(tonumber(oh)*60+tonumber(om))*60*(sign=='-' and -1 or 1)
    end
    y,m,d,h,n=tonumber(y),tonumber(m),tonumber(d),tonumber(h),tonumber(n)
    local day=ordinal(y,m,d)
    if not day or h>23 or n>59 or sec>59 then return nil end
    return (day-719163)*86400+h*3600+n*60+sec-offset,offset
end
local function degrees(t)
    return type(t)=='table' and t.unit=='°C' and number(t.value) and t.value>=-100 and t.value<=70
end
local function condition(t)
    return type(t)=='table' and type(t.code)=='string' and t.code:match('^%d%d%d$') and safeText(t.text)
end
local function segment(t,allowMissingProbability)
    if type(t)~='table' or not condition(t.condition) then return false end
    local first=timestamp(t.forecastStartTime);local last=timestamp(t.forecastEndTime)
    if not first or not last or last<=first or last-first>86400 then return false end
    local p=t.precipitation
    if p==nil and allowMissingProbability then return true end
    return type(p)=='table' and number(p.probability) and p.probability>=0 and p.probability<=1
end
-- Normalize documented city fields without inventing precipitation probabilities
-- or conflating observed time with receipt time. No scraping is used.
function M.normalizeCurrent(data)
    if type(data)=='table' and data.code=='200' and type(data.now)=='table' then
        local c=data.now
        if not timestamp(c.obsTime) then return nil end
        return {condition={code=c.icon,text=c.text},temperature={value=tonumber(c.temp),unit='°C'},
            observed_at=c.obsTime,published_at=data.updateTime,city_page=data.fxLink,source_api='city-v7'}
    end
    return data
end
function M.normalizeDaily(data)
    if type(data)~='table' or type(data.daily)~='table' then return data end
    if data.code~='200' or not timestamp(data.updateTime) then return nil end
    local offset=data.updateTime:match('([+-]%d%d:%d%d)$') or (data.updateTime:sub(-1)=='Z' and 'Z' or nil)
    if not offset then return nil end
    local out={days={},source_api='city-v7',published_at=data.updateTime,city_page=data.fxLink}
    for _,row in ipairs(data.daily) do
        if type(row)~='table' then return nil end
        if type(row.fxDate)~='string' then return nil end
        local first,seconds=timestamp(row.fxDate..'T00:00'..offset)
        if not first then return nil end
        local nextDate=os.date('!%Y-%m-%d',first+seconds+86400)
        local astro={}
        if type(row.sunrise)=='string' and row.sunrise~='' then astro.sunrise=row.fxDate..'T'..row.sunrise..offset end
        if type(row.sunset)=='string' and row.sunset~='' then astro.sunset=row.fxDate..'T'..row.sunset..offset end
        out.days[#out.days+1]={forecastStartTime=row.fxDate..'T00:00'..offset,
            forecastEndTime=nextDate..'T00:00'..offset,
            temperatureMax={value=tonumber(row.tempMax),unit='°C'},temperatureMin={value=tonumber(row.tempMin),unit='°C'},astro=astro,
            daytime={forecastStartTime=row.fxDate..'T07:00'..offset,forecastEndTime=row.fxDate..'T19:00'..offset,
                condition={code=row.iconDay,text=row.textDay}},
            nighttime={forecastStartTime=row.fxDate..'T19:00'..offset,forecastEndTime=nextDate..'T07:00'..offset,
                condition={code=row.iconNight,text=row.textNight}}}
    end
    return out
end
function M.validCurrent(data)
    return type(data)=='table' and not data.error and condition(data.condition) and degrees(data.temperature) and true or false
end
function M.validDaily(data)
    if type(data)~='table' or type(data.days)~='table' or #data.days<5 or #data.days>10 then return false end
    local previous
    for _,d in ipairs(data.days) do
        if type(d)~='table' then return false end
        local first,offset=timestamp(d.forecastStartTime);local last=timestamp(d.forecastEndTime)
        if not first or not last or last<=first or last-first>90000 then return false end
        if previous and first~=previous then return false end
        if not degrees(d.temperatureMin) or not degrees(d.temperatureMax) or d.temperatureMin.value>d.temperatureMax.value
            or not segment(d.daytime,data.source_api=='city-v7') or not segment(d.nighttime,data.source_api=='city-v7') then return false end
        previous=last
    end
    return true
end
function M.icon(code,isDay)
    code=tonumber(code)
    if code==150 then return isDay==0 and 'night' or 'sunny' end
    if code==100 or code==102 then return isDay==0 and 'night' or 'sunny' end
    if code==101 or code==103 or code==151 or code==152 or code==153 then return isDay==0 and 'cloudy-night' or 'cloudy' end
    if code==104 then return 'overcast' end
    if code and code>=302 and code<=304 then return isDay==0 and 'thunder-night' or 'thunder' end
    if code==309 then return 'drizzle' end
    if code and code>=300 and code<=399 then return 'rain' end
    if code and code>=400 and code<=499 then return 'snow' end
    if code and code>=500 and code<=515 then return 'fog' end
    return 'unknown'
end
local function localDate(now,offset) return os.date('!%Y-%m-%d',now+offset) end
function M.view(current,daily,now)
    local out={provider='QWeather'}
    local today,offset= nil, 8*3600 -- Replaced by location's explicit API offset once daily data exists.
    if daily and now-daily.at<=86400 and M.validDaily(daily.data) then
        local list=daily.data.days
        local _,firstOffset=timestamp(list[1].forecastStartTime);offset=firstOffset
        for i,d in ipairs(list) do
            local start=timestamp(d.forecastStartTime);local finish=timestamp(d.forecastEndTime)
            if start<=now and now<finish then today=i;break end
        end
        if today and #list-today+1>=5 then
            local result={time={},temperature_2m_max={},temperature_2m_min={},q_icons={},q_tips={}}
            for i=1,5 do
                local d=list[today+i-1]
                local date=localDate(timestamp(d.forecastStartTime),offset)
                local nightStart=timestamp(d.nighttime.forecastStartTime)
                if daily.data.source_api=='city-v7' and type(d.astro)=='table' then nightStart=timestamp(d.astro.sunset) or nightStart end
                local useNight=i==1 and now>=nightStart
                local chosen=useNight and d.nighttime or d.daytime
                result.time[i]=date
                result.temperature_2m_max[i]=d.temperatureMax.value
                result.temperature_2m_min[i]=d.temperatureMin.value
                result.q_icons[i]=M.icon(chosen.condition.code,useNight and 0 or 1)
                local function probability(t)
                    return t.precipitation and '，降水概率 '..math.floor(t.precipitation.probability*100+0.5)..'%' or ''
                end
                result.q_tips[i]=date..' 白天：'..safeText(d.daytime.condition.text)..probability(d.daytime)
                    ..'；夜间：'..safeText(d.nighttime.condition.text)..probability(d.nighttime)..'。'
                if useNight then result.q_tips[i]=result.q_tips[i]..'当前图标显示今晚。' end
            end
            out.daily=result
            out.daily_at=daily.at
        end
    end
    local observed=current and current.data.observed_at and timestamp(current.data.observed_at) or nil
    if current and now-current.at<=10800 and (not observed or (observed<=now+300 and now-observed<=10800)) and M.validCurrent(current.data) then
        local minute=tonumber(os.date('!%H',now+offset))*60+tonumber(os.date('!%M',now+offset))
        local isDay=(minute>=420 and minute<1140) and 1 or 0
        if today then
            local astro=daily.data.days[today].astro
            local sunrise=type(astro)=='table' and timestamp(astro.sunrise) or nil
            local sunset=type(astro)=='table' and timestamp(astro.sunset) or nil
            if sunrise and sunset then isDay=(now>=sunrise and now<sunset) and 1 or 0 end
        end
        out.current={temperature_2m=current.data.temperature.value,q_text=safeText(current.data.condition.text),
            q_icon=M.icon(current.data.condition.code,isDay),is_day=isDay,observed_at=current.data.observed_at}
        out.current_at=current.at
    end
    if not out.current and not out.daily then return nil end
    out.city_page=(current and current.data.city_page) or (daily and daily.data.city_page)
    return out
end
function M.credentials(data)
    if type(data)~='table' or type(data.apiHost)~='string' or type(data.apiKey)~='string' then return nil end
    local host=data.apiHost:lower()
    if #host>253 or not host:match('^[a-z0-9][a-z0-9%.%-]+%.qweatherapi%.com$') or host:find('%.%.') then return nil end
    for label in host:gmatch('[^.]+') do
        if #label>63 or label:sub(1,1)=='-' or label:sub(-1)=='-' then return nil end
    end
    if #data.apiKey<16 or #data.apiKey>256 or data.apiKey:find('[^a-zA-Z0-9_%-]') then return nil end
    return {host=host,key=data.apiKey}
end
function M.new(ctx)
    local self={ctx=ctx,parts={},flights={},nextAt={},attemptAt={},errors={},key=nil,loc=nil,lastMinute=nil}
    self.auth=M.credentials(ctx.read(ctx.resources..'QWeather.local.json'))
    if not self.auth then self.configError='请检查QWeather.local.json中的apiHost和apiKey。' end
    local function measure(kind) return kind=='current' and 'QWeatherCurrent' or 'QWeatherDaily' end
    local function path(kind) return ctx.cacheDir..'qweather-'..kind..'-cache.json' end
    function self:feedback(text,seconds)
        self.notice=text;self.noticeUntil=os.time()+(seconds or 5);ctx.changed()
    end
    local function finishManual()
        if self.manualRefresh and not next(self.flights) then
            self.manualRefresh=false
            if not self.errors.current and not self.errors.daily then
                self.notice='已更新 · '..os.date('%H:%M');self.noticeUntil=os.time()+5
            end
        end
    end
    function self:load(kind)
        local p=path(kind);ctx.storage.recover(p)
        local saved=ctx.read(p);local valid=kind=='current' and M.validCurrent or M.validDaily
        local normalize=kind=='current' and M.normalizeCurrent or M.normalizeDaily
        local normalized=type(saved)=='table' and normalize(saved.data) or nil
        if type(saved)=='table' and saved.version==2 and saved.key==self.key
            and (not ctx.cityOnly or (type(normalized)=='table' and normalized.source_api=='city-v7'))
            and type(saved.at)=='number' and saved.at<=os.time()+300 and os.time()-saved.at<=604800 and valid(normalized) then
            self.parts[kind]={data=normalized,at=saved.at}
        end
    end
    function self:setLocation(loc,key)
        if self.key==key then return end
        self.key=key;self.loc=loc;self.parts={};self.errors={};self.nextAt={};self.rolloverRequested=false
        self.manualRefresh=false;self.notice=nil;self.noticeUntil=nil
        self:load('current');self:load('daily')
        self:tick()
    end
    function self:request(kind,manual)
        if self.configError or not self.loc then return false,'location',0 end
        if self.flights[kind] then return false,'busy',0 end
        local now=os.time()
        local spacing=manual and 10 or 60
        if self.attemptAt[kind] and now-self.attemptAt[kind]<spacing then
            return false,'cooldown',math.ceil(spacing-(now-self.attemptAt[kind]))
        end
        self.attemptAt[kind]=now;self.nextAt[kind]=now+(kind=='current' and 900 or 3600)
        local lat=string.format('%.2f',self.loc.latitude):gsub(',','.')
        local lon=string.format('%.2f',self.loc.longitude):gsub(',','.')
        local args='-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "'..ctx.resources..'FetchQWeather.ps1"'
            ..' -Kind '..kind..' -Latitude '..lat..' -Longitude '..lon
        self.flights[kind]={key=self.key,at=now}
        -- The fixed helper reads credentials locally and decodes gzip. Only a
        -- fixed request kind and validated numeric coordinates enter arguments.
        ctx.set(measure(kind),'Parameter',args)
        ctx.skin:Bang('!EnableMeasure',measure(kind))
        ctx.skin:Bang('!UpdateMeasure',measure(kind))
        ctx.skin:Bang('!CommandMeasure',measure(kind),'Run')
        ctx.log('QWeather '..kind..' request started; credentials omitted.')
        return true
    end
    function self:loaded(kind)
        local flight=self.flights[kind]
        ctx.skin:Bang('!DisableMeasure',measure(kind))
        self.flights[kind]=nil
        if not flight or flight.key~=self.key then return end
        local raw=ctx.skin:GetMeasure(measure(kind)):GetStringValue()
        if type(raw)~='string' or #raw>1048576 then self:failed(kind);return end
        local ok,data=pcall(ctx.json.decode,raw)
        if ok then data=(kind=='current' and M.normalizeCurrent or M.normalizeDaily)(data) end
        local valid=kind=='current' and M.validCurrent or M.validDaily
        if not ok or not valid(data) or (ctx.cityOnly and data.source_api~='city-v7') then
            local prefix=string.format('%02X %02X',raw:byte(1) or 0,raw:byte(2) or 0)
            local code=ok and type(data)=='table' and tostring(data.code or data.status or '') or ''
            if not code:match('^%d+$') then code='unavailable' end
            ctx.log('QWeather '..kind..' response rejected; bytes='..#raw..', prefix='..prefix..', status='..code..'.')
            self:failed(kind);return
        end
        -- Require a currently applicable five-day view, not just structurally valid old data.
        if kind=='daily' and not M.view(nil,{data=data,at=os.time()},os.time()) then self:failed(kind);return end
        local at=os.time();self.parts[kind]={data=data,at=at};self.errors[kind]=nil
        if kind=='daily' then self.rolloverRequested=false end
        self.nextAt[kind]=at+(kind=='current' and 900 or 3600)
        local saved='{"version":2,"key":'..ctx.quote(self.key)..',"at":'..at..',"data":'..raw..'}'
        local wrote=ctx.storage.write(path(kind),saved)
        if not wrote then ctx.log('QWeather cache save failed; prior backup retained.') end
        ctx.log('QWeather '..kind..' updated successfully; credentials omitted.')
        finishManual()
        ctx.changed()
    end
    function self:failed(kind)
        local flight=self.flights[kind]
        ctx.skin:Bang('!DisableMeasure',measure(kind));self.flights[kind]=nil
        if flight and flight.key~=self.key then return end
        self.errors[kind]=true;self.nextAt[kind]=os.time()+900
        ctx.log('QWeather '..kind..' unavailable; same-provider cache retained, no provider fallback.')
        finishManual()
        ctx.changed()
    end
    function self:tick()
        if self.configError or not self.loc then return end
        local now=os.time()
        if self.noticeUntil and now>=self.noticeUntil then self.notice=nil;self.noticeUntil=nil;ctx.changed() end
        local view=M.view(self.parts.current,self.parts.daily,now)
        if self.parts.daily and (not view or not view.daily) and not self.rolloverRequested then
            -- The new day must not retain yesterday's five labels as today's forecast.
            self.nextAt.daily=math.min(self.nextAt.daily or now,now)
            self.rolloverRequested=true
        end
        for _,kind in ipairs({'current','daily'}) do
            local flight=self.flights[kind]
            if flight and now-flight.at>120 and not self.errors[kind] then
                -- Keep the flight occupied until the helper finishes: an old reply must
                -- never be attributed to a later request/location.
                self.errors[kind]=true;ctx.changed()
            end
            if now>=(self.nextAt[kind] or 0) then self:request(kind,false) end
        end
        local minute=math.floor(now/60)
        if minute~=self.lastMinute then self.lastMinute=minute;ctx.changed() end
    end
    function self:retry()
        local current,whyCurrent,waitCurrent=self:request('current',true)
        local daily,whyDaily,waitDaily=self:request('daily',true)
        if current or daily or whyCurrent=='busy' or whyDaily=='busy' then
            self.manualRefresh=true;self.notice=nil;self.noticeUntil=nil;ctx.changed()
        elseif whyCurrent=='cooldown' or whyDaily=='cooldown' then
            local seconds=math.max(waitCurrent or 0,waitDaily or 0)
            self:feedback('请 '..seconds..' 秒后再刷新',seconds)
        else self:feedback('等待有效位置后刷新',5) end
    end
    function self:view() return M.view(self.parts.current,self.parts.daily,os.time()) end
    function self:status()
        local now=os.time()
        if self.manualRefresh and next(self.flights) then return '正在刷新天气…' end
        if self.errors.current then return '当前天气更新失败 · 点击重试' end
        if self.errors.daily then return '预报更新失败 · 点击重试' end
        local observed=self.parts.current and self.parts.current.data.observed_at
        if observed and (timestamp(observed) or 0)>now+300 then return '观测时间异常 · 请检查系统时间' end
        if observed and now-(timestamp(observed) or 0)>3600 then return '观测数据更新延迟 · 点击重试' end
        if self.parts.current and now-self.parts.current.at>2700 then return '当前天气可能已过期 · 点击重试' end
        if self.parts.daily and now-self.parts.daily.at>7200 then return '预报可能已过期 · 点击重试' end
        if self.notice and now<(self.noticeUntil or 0) then return self.notice end
        return ''
    end
    return self
end
M.timestamp=timestamp
return M
