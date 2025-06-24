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

function convert_time(t)
    local h, m, s, ms = t:match("(%d+):(%d+):(%d+)[,.](%d+)")
    return string.format("%01d:%02d:%02d.%02d", h, m, s, tonumber(ms) / 10)
end

function parse_time_to_seconds(t)
    local h, m, s, ms = t:match("(%d+):(%d+):(%d+)[,.](%d+)")
    return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s) + tonumber(ms)/1000
end

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

function extract_selected_subs()
    local tracks = mp.get_property_native("track-list")
    local sid1 = tonumber(mp.get_property("sid"))
    local sid2 = tonumber(mp.get_property("secondary-sid"))
    if not sid1 or not sid2 then
        mp.osd_message("❌ İki altyazı aynı anda aktif değil.")
        return nil, nil
    end

    local sub_paths = {}
    local input_file = mp.get_property("path")
    local temp_dir = utils.join_path(mp.get_property("temp-directory") or ".", "merge_temp")
    local sub_temp_paths = {
        utils.join_path(temp_dir, "sub1.srt"),
        utils.join_path(temp_dir, "sub2.srt")
    }
    local found = 0
    local used_temp = false
    for _, track in ipairs(tracks) do
        if track.type == "sub" and (track.id == sid1 or track.id == sid2) then
            found = found + 1
            if track.external and track["external-filename"] then
                -- Harici altyazı dosyasını doğrudan kullan
                table.insert(sub_paths, track["external-filename"])
            else
                -- Dahili altyazı: ffmpeg ile çıkar
                if not used_temp then
                    if not utils.readdir(temp_dir) then
                        os.execute('mkdir "' .. temp_dir .. '"')
                    end
                    used_temp = true
                end
                local ff_index = track.ff_index and (track.ff_index - 1) or (track.id + 1)
                local ret = utils.subprocess({
                    args = {"ffmpeg", "-y", "-i", input_file, "-map", "0:" .. tostring(ff_index), sub_temp_paths[found]},
                    capture_stderr = true,
                    capture_stdout = true
                })
                if ret.status ~= 0 then
                    mp.osd_message("❌ FFmpeg ile altyazı çıkarılamadı.\nHata: " .. (ret.stderr or "(boş)"))
                    return nil, nil
                end
                table.insert(sub_paths, sub_temp_paths[found])
            end
        end
    end

    if #sub_paths ~= 2 then
        mp.osd_message("❌ Altyazı yolları eşleşemedi.")
        return nil, nil
    end
    return sub_paths, used_temp and temp_dir or nil
end

function delete_dir_recursive(path)
    local files = utils.readdir(path)
    if files then
        for _, file in ipairs(files) do
            local fpath = utils.join_path(path, file)
            local ok, err = os.remove(fpath)
            -- hata olursa devam et
        end
    end
    -- klasörü silmeyi dene
    local ok, err = os.remove(path)
    -- Eğer klasör hâlâ varsa, Windows komut satırı ile zorla sil
    if utils.readdir(path) then
        os.execute('rmdir /s /q "' .. path .. '"')
    end
end

function merge_selected_subs()
    local paths, temp_dir = extract_selected_subs()
    if not paths then return end

    local sub1 = parse_srt(paths[1])
    local sub2 = parse_srt(paths[2])
    if not sub1 or not sub2 then
        mp.osd_message("❌ Altyazılar parse edilemedi.")
        if temp_dir then delete_dir_recursive(temp_dir) end
        return
    end

    local merged_ass = ass_template_top
    local used = {}

    for _, s in ipairs(sub1) do
        local t = find_nearest(sub2, s.start, used)
        if t then
            merged_ass = merged_ass ..
                string.format("Dialogue: 0,%s,%s,Bottom,,0,0,0,,%s\n", convert_time(s.start), convert_time(s.stop), s.text) ..
                string.format("Dialogue: 0,%s,%s,Top,,0,0,0,,%s\n", convert_time(t.start), convert_time(t.stop), t.text)
        end
    end

    local temp_path = utils.join_path(mp.get_property("temp-directory") or ".", "merged_selected.ass")
    local f = io.open(temp_path, "w")
    f:write(merged_ass)
    f:close()

    mp.commandv("sub-remove", "0")
    mp.commandv("sub-add", temp_path)
    mp.osd_message("✅ Seçili altyazılar birleştirildi 🎬")

    if temp_dir then
        delete_dir_recursive(temp_dir)
    end

    mp.set_property("secondary-sid", "no")
end

mp.add_key_binding("ctrl+b", "merge_selected_subs", merge_selected_subs)
