local utils = require 'mp.utils'
local msg = require 'mp.msg'
local ass_template_top = [[
[Script Info]
ScriptType: v4.00+
PlayResX: 1920
PlayResY: 1080

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Bottom, Arial, 50, &H00FFFFFF, &H000000FF, &H00000000, &H64000000, 0, 0, 0, 0, 100, 100, 0.0, 0.0, 1, 2, 0, 2, 20, 20, 50, 1
Style: Top, Arial, 50, &H00FFFF00, &H000000FF, &H00000000, &H64000000, 0, 0, 0, 0, 100, 100, 0.0, 0.0, 1, 2, 0, 8, 20, 20, 950, 1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
]]

-- Basit SRT satırı parse eden fonksiyon
function parse_srt(filename)
    local subs = {}
    local f = io.open(filename, "r")
    if not f then return nil end
    local index, time, text = nil, nil, ""
    for line in f:lines() do
        line = line:gsub("\r", "")
        if line:match("^%d+$") then
            index = tonumber(line)
        elseif line:match("%d%d:%d%d:%d%d") then
            time = line
        elseif line == "" then
            if index and time and text ~= "" then
                local start_time, end_time = time:match("(%d%d:%d%d:%d%d[,.]%d+)%s+-->%s+(%d%d:%d%d:%d%d[,.]%d+)")
                table.insert(subs, {start=start_time, stop=end_time, text=text})
            end
            index, time, text = nil, nil, ""
        else
            text = text == "" and line or text .. "\\N" .. line
        end
    end
    f:close()
    return subs
end

-- ASS formatında zaman
function convert_time(t)
    local h, m, s, ms = t:match("(%d+):(%d+):(%d+)[,.](%d+)")
    return string.format("%01d:%02d:%02d.%02d", h, m, s, tonumber(ms) / 10)
end

function merge_subs()
    local tracks = mp.get_property_native("track-list")
    local sub_files = {}
    for _, t in ipairs(tracks) do
        if t.type == "sub" and t.external and t["external-filename"] then
            table.insert(sub_files, t["external-filename"])
        end
    end
    if #sub_files < 2 then
        msg.error("En az iki harici altyazı gerekiyor.")
        return
    end

    local sub1 = parse_srt(sub_files[1])
    local sub2 = parse_srt(sub_files[2])
    if not sub1 or not sub2 then
        msg.error("Altyazılar parse edilemedi.")
        return
    end

    local merged_ass = ass_template_top
    for i = 1, math.min(#sub1, #sub2) do
        local s = sub1[i]
        local t = sub2[i]
        merged_ass = merged_ass ..
            string.format("Dialogue: 0,%s,%s,Bottom,,0,0,0,,%s\n", convert_time(s.start), convert_time(s.stop), s.text) ..
            string.format("Dialogue: 0,%s,%s,Top,,0,0,0,,%s\n", convert_time(t.start), convert_time(t.stop), t.text)
    end
    --en yakın olanı bulan fonksiyon    
    function find_nearest(sub_list, target_time, used_indexes)
        local min_diff = math.huge
        local best = nil
        local index = nil
        for i, s in ipairs(sub_list) do
            if not used_indexes[i] then
                local t = parse_time_to_seconds(s.start)
                local diff = math.abs(t - parse_time_to_seconds(target_time))
                if diff < min_diff then
                    min_diff = diff
                    best = s
                    index = i
                end
            end
        end
        if index then used_indexes[index] = true end
        return best
    end
    
    function parse_time_to_seconds(t)
        local h, m, s, ms = t:match("(%d+):(%d+):(%d+)[,.](%d+)")
        return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s) + tonumber(ms)/1000
    end
    -- Geçici dosya yaz
    local temp_path = utils.join_path(mp.get_property("temp-directory") or ".", "merged.ass")
    local f = io.open(temp_path, "w")
    f:write(merged_ass)
    f:close()

    -- Yeni altyazıyı yükle
    mp.commandv("sub-remove", "0")
    mp.commandv("sub-add", temp_path)
    mp.osd_message("Altyazılar birleştirildi 🎬")
end

-- Ctrl+b için key-binding
mp.add_key_binding("ctrl+b", "merge_subs", merge_subs)
