-- Calendar accent only. No network, external process, global settings, or refresh.
local storage,hue,visible,currentName= nil,358,false,'Red'
local presets={
    Red={title={215,48,52},today={239,65,70},hue=358,label='经典红'},
    Blue={title={30,105,200},today={37,126,234},hue=213,label='湖蓝'},
    Cyan={title={0,118,140},today={0,149,173},hue=188,label='青色'},
    Mint={title={0,119,98},today={0,143,116},hue=169,label='薄荷绿'},
    Purple={title={112,63,190},today={139,82,222},hue=264,label='紫色'},
}
-- Hidden meters still contribute to Rainmeter's window bounds. Keep them inside
-- the original card while closed, then restore their panel positions on open.
local panelY={ColorPanel=300,ColorPanelTitle=314,ColorClose=314,ColorRed=351,
    ColorBlue=351,ColorCyan=351,ColorMint=351,ColorPurple=351,HueBar=377,
    HueThumb=386,ColorValue=407,ColorReset=407,ColorHint=429}
local function finite(n) return type(n)=='number' and n==n and math.abs(n)<100000 end
local function set(n,k,v) SKIN:Bang('!SetOption',n,k,tostring(v)) end
local function layout(open)
    local scale=tonumber(SKIN:GetVariable('Scale','1')) or 1
    for name,y in pairs(panelY) do set(name,'Y',open and y*scale or 0) end
end
local function rgb(t) return table.concat(t,',') end
local function hex(t) return string.format('#%02X%02X%02X',t[1],t[2],t[3]) end
local function parse(s)
    if type(s)~='string' then return nil end
    local r,g,b=s:match('^(%d+),(%d+),(%d+)$')
    if not r then return nil end
    r,g,b=tonumber(r),tonumber(g),tonumber(b)
    if r>255 or g>255 or b>255 then return nil end
    return {r,g,b}
end
local function luminance(t)
    local function linear(n) n=n/255;return n<=0.04045 and n/12.92 or ((n+0.055)/1.055)^2.4 end
    return 0.2126*linear(t[1])+0.7152*linear(t[2])+0.0722*linear(t[3])
end
local function textColor(t)
    local light=luminance(t)
    local white=1.05/(light+0.05)
    local dark=(light+0.05)/(luminance({31,41,55})+0.05)
    return dark>white and '31,41,55' or '255,255,255'
end
local function hsv(h)
    h=(h%360)/60
    local s,v=0.74,0.88
    local c=v*s;local x=c*(1-math.abs(h%2-1));local m=v-c
    local r,g,b
    if h<1 then r,g,b=c,x,0 elseif h<2 then r,g,b=x,c,0
    elseif h<3 then r,g,b=0,c,x elseif h<4 then r,g,b=0,x,c
    elseif h<5 then r,g,b=x,0,c else r,g,b=c,0,x end
    return {math.floor((r+m)*255+0.5),math.floor((g+m)*255+0.5),math.floor((b+m)*255+0.5)}
end
local function titleShade(t)
    local out={math.floor(t[1]*0.78+0.5),math.floor(t[2]*0.78+0.5),math.floor(t[3]*0.78+0.5)}
    while luminance(out)>0.17 do
        for i=1,3 do out[i]=math.floor(out[i]*0.94) end
    end
    return out
end
local function controls(today)
    local scale=tonumber(SKIN:GetVariable('Scale','1')) or 1
    set('HueThumb','X',(26+(hue or 0)/360*232)*scale)
    set('ColorValue','Text',(presets[currentName] and presets[currentName].label or '自定义')..'  '..hex(today))
    set('ColorValue','FontColor',SKIN:GetVariable('CalendarTitleColor','215,48,52'))
end
local function apply(name,title,today,newHue,todayText)
    local path=SKIN:GetVariable('@')..'Refined\\Accent.inc'
    local lines={'[Variables]','CalendarAccent='..name,'CalendarTitleColor='..rgb(title),
        'CalendarTodayColor='..rgb(today),'CalendarTodayTextColor='..todayText,'CalendarHue='..string.format('%.2f',newHue):gsub(',','.')}
    local ok,err=storage.write(path,table.concat(lines,'\n')..'\n')
    if not ok then
        set('ColorValue','Text','颜色保存失败，请重试')
        SKIN:Bang('!Log','Calendar accent save failed; prior file retained: '..tostring(err),'Warning')
        SKIN:Bang('!UpdateMeter','ColorValue');SKIN:Bang('!Redraw');return false
    end
    currentName,hue=name,newHue
    for _,entry in ipairs({{'CalendarAccent',name},{'CalendarTitleColor',rgb(title)},
        {'CalendarTodayColor',rgb(today)},{'CalendarTodayTextColor',todayText},{'CalendarHue',newHue}}) do
        SKIN:Bang('!SetVariable',entry[1],tostring(entry[2]))
    end
    controls(today)
    -- Draw keeps the existing month offset; no !Refresh and no weather commands.
    SKIN:Bang('!CommandMeasure','CalendarScript','Draw()')
    SKIN:Bang('!UpdateMeter','*');SKIN:Bang('!Redraw')
    return true
end
function Initialize()
    storage=dofile(SKIN:GetVariable('@')..'Refined\\Storage.lua')
    local path=SKIN:GetVariable('@')..'Refined\\Accent.inc'
    if storage.recover(path) then SKIN:Bang('!Refresh');return end
    currentName=SKIN:GetVariable('CalendarAccent','Red')
    hue=tonumber(SKIN:GetVariable('CalendarHue',''))
    if not finite(hue) then hue=(presets[currentName] or presets.Red).hue end
    hue=math.max(0,math.min(360,hue))
    visible=false
    layout(false)
    controls(parse(SKIN:GetVariable('CalendarTodayColor','')) or presets.Red.today)
end
function Update() return 0 end
function Apply(name)
    local p=presets[name]
    if p then return apply(name,p.title,p.today,p.hue,'255,255,255') end
    return false
end
function SetHue(percent)
    percent=tonumber(percent)
    if not finite(percent) then return false end
    local h=math.max(0,math.min(100,percent))*3.6
    local today=hsv(h)
    return apply('Custom',titleShade(today),today,h,textColor(today))
end
function Step(delta)
    delta=tonumber(delta)
    if not finite(delta) or math.abs(delta)>30 then return false end
    return SetHue(((hue+delta)%360)/3.6)
end
function Toggle()
    visible=not visible
    layout(visible)
    SKIN:Bang(visible and '!ShowMeterGroup' or '!HideMeterGroup','CalendarColors')
    SKIN:Bang('!UpdateMeter','*');SKIN:Bang('!Redraw')
end
function Close()
    visible=false;layout(false);SKIN:Bang('!HideMeterGroup','CalendarColors')
    SKIN:Bang('!UpdateMeter','*');SKIN:Bang('!Redraw')
end
function LogState()
    local color=parse(SKIN:GetVariable('CalendarTodayColor','')) or presets.Red.today
    SKIN:Bang('!Log','Calendar accent='..currentName..'; hue='..tostring(hue)..'; color='..rgb(color)
        ..'; panel='..tostring(visible)..'; size='..SKIN:GetVariable('CURRENTCONFIGWIDTH','?')..'x'..SKIN:GetVariable('CURRENTCONFIGHEIGHT','?')
        ..'; position='..SKIN:GetVariable('CURRENTCONFIGX','?')..','..SKIN:GetVariable('CURRENTCONFIGY','?'),'Notice')
end
