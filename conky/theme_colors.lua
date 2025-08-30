-- Returns text/header color for the current time
function theme_color()
    local hour = tonumber(os.date("%H"))

    if hour >= 6 and hour < 12 then
        return '${color #FFB347}'  -- Sunrise: warm golden
    elseif hour >= 12 and hour < 18 then
        return '${color #7AA2F7}'  -- Noon: bright blue
    elseif hour >= 18 and hour < 24 then
        return '${color #FF6E3A}'  -- Sunset: orange/red
    else
        return '${color #5A6FFF}'  -- Night: deep blue
    end
end

-- Returns bar color for CPU/Mem/Disk/Net
function bar_color()
    local hour = tonumber(os.date("%H"))

    if hour >= 6 and hour < 12 then
        return '#FFB347'  -- Sunrise
    elseif hour >= 12 and hour < 18 then
        return '#7AA2F7'  -- Noon
    elseif hour >= 18 and hour < 24 then
        return '#FF6E3A'  -- Sunset
    else
        return '#5A6FFF'  -- Night
    end
end
