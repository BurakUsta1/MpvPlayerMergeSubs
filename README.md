## Language / Dil

[Türkçe](README_TR.md)

# MPV Subtitle Merger

This Lua script for MPV player allows you to merge two currently active subtitles into a single `.ass` subtitle file, displaying one at the bottom and the other at the top of the screen. This is particularly useful for language learners or anyone who wants to see two different translations or a translation and the original text simultaneously.

![Ekran görüntüsü 2025-06-24 113218](https://github.com/user-attachments/assets/a1c8804c-499c-4a0d-9fb0-c0537557d3ab)

![Ekran görüntüsü 2025-06-24 113306](https://github.com/user-attachments/assets/507c34ad-d8ad-4ad2-9efa-8e20f4d05d20)


## Features

* **Merge Subtitles**: Combines two active subtitle tracks (internal or external) into one `.ass` file.
* **Dual Display**: Displays one subtitle track at the bottom and the other at the top of the video.
* **Time Synchronization**: Attempts to synchronize subtitles based on the nearest start time.
* **Automatic Cleanup**: Removes temporary files generated during the merging process.

## Installation

1.  **Locate MPV Scripts Directory**:
    * **Windows**: `C:\Users\YourUsername\AppData\Roaming\mpv\scripts\`
    * **Linux/macOS**: `~/.config/mpv/scripts/` or `~/.mpv/scripts/`

2.  **Download the Script**:
    Download `merge-subs.lua` and place it in the MPV `scripts` directory.

3.  **Ensure FFmpeg is Installed**:
    This script uses `ffmpeg` to extract internal subtitle tracks. Make sure `ffmpeg` is installed on your system and accessible from your PATH. If you don't have it, you can download it from [ffmpeg.org](https://ffmpeg.org/download.html).

## Usage

1.  **Open a Video with MPV**:
    Open any video file in MPV that has at least two subtitle tracks (either internal or external).

2.  **Activate Two Subtitle Tracks**:
    * **Primary Subtitle**: Select your first subtitle track using MPV's subtitle selection options (e.g., by pressing `j` or `J` to cycle through tracks, or using the OSD menu). This will be the "Bottom" subtitle in the merged output.
    * **Secondary Subtitle**: Select your second subtitle track. This can be done via MPV's `secondary-sid` option. For example, you can use the OSD menu to select a secondary subtitle or use a key binding in your `input.conf` (e.g., `s cycle secondary-sid`). This will be the "Top" subtitle in the merged output.

3.  **Merge Subtitles**:
    Press `Ctrl+B` (the default key binding) to trigger the merging process.

4.  **Confirmation**:
    A message "✅ Seçili altyazılar birleştirildi 🎬" (Selected subtitles merged) will appear on the OSD if successful. If there's an issue, an error message will be displayed.

## How it Works

The script performs the following steps:

1.  **Identifies Active Subtitles**: It checks for two active subtitle tracks (`sid` and `secondary-sid`).
2.  **Extracts Subtitle Files**:
    * If the subtitle is an external file, it uses its path directly.
    * If the subtitle is embedded within the video file, it uses `ffmpeg` to extract it to a temporary `.srt` file.
3.  **Parses SRT Files**: Both subtitle files are parsed into Lua tables.
4.  **Merges Subtitles into ASS Format**:
    * It iterates through the primary subtitle track.
    * For each subtitle entry in the primary track, it finds the "nearest" corresponding subtitle entry in the secondary track based on start time.
    * It then formats these pairs into an Advanced SubStation Alpha (`.ass`) format, applying predefined styles (`Bottom` and `Top`).
5.  **Loads Merged Subtitle**: The newly created `.ass` file is loaded into MPV, and the `secondary-sid` is set to "no" to avoid conflicts.
6.  **Cleans Up**: Any temporary files and directories created for extracting internal subtitles are removed.

## Configuration

You can customize the appearance of the merged subtitles by editing the `ass_template_top` variable within the `merge-subs.lua` file. Specifically, you can modify the `Style: Bottom` and `Style: Top` lines to change:

* **Fontname**: `Arial`
* **Fontsize**: `50`
* **PrimaryColour**: `&H00FFFFFF` (ARGB hex code for white) for Bottom, `&H00FFFF00` (ARGB hex code for yellow) for Top.
* **OutlineColour**: `&H00000000` (black)
* **BackColour**: `&H64000000` (semi-transparent black)
* **Alignment**: `2` (bottom center) for Bottom, `8` (top center) for Top.
* **MarginV**: `50` for Bottom (distance from bottom), `950` for Top (distance from top).

Refer to the [ASS (Advanced SubStation Alpha) format documentation](http://docs.aegisub.org/3.2/ASS_Tags/) for more details on styling options.

## Troubleshooting

* **"❌ İki altyazı aynı anda aktif değil." (Two subtitles are not active at the same time.)**: Ensure both a primary (`sid`) and secondary (`secondary-sid`) subtitle track are active in MPV.
* **"❌ FFmpeg ile altyazı çıkarılamadı." (Could not extract subtitle with FFmpeg.)**:
    * Check if FFmpeg is installed and in your system's PATH.
    * Ensure the video file is not corrupted or has properly muxed internal subtitle tracks.
* **"❌ Altyazılar parse edilemedi." (Subtitles could not be parsed.)**:
    * Verify that your `.srt` files are correctly formatted.
    * If the extracted temporary files are empty or malformed, there might be an issue with the FFmpeg extraction.
* **Subtitles not synchronizing correctly**: The script uses a "nearest start time" approach. For highly desynchronized subtitles, this might not yield perfect results. You may need to manually adjust one of the subtitle tracks in MPV before merging (e.g., using `Alt+j` or `Alt+k`).

## Contributing

Feel free to open issues or pull requests if you have suggestions for improvements or bug fixes.

---
**Note**: Replace `username`, `repo-name`, and `path/to/your/screenshot.png` with your actual GitHub details and the path to a screenshot/GIF demonstrating the script in action.
