# Setting up your USB drive

Couchmark doesn't use a server or online database. It looks at the folders on your USB drive, and **the folder names are what you see on the TV**. Organize the drive as described here and everything appears in the right place.

**Shortcut:** download `couchmark-usb-starter.zip` from the [Releases](https://github.com/johncharbo95/couchmark/releases) page and unzip it onto the drive. You get the three empty folders described below, ready to fill.

## At a glance

```
USB drive
├── Movies/                        ← one folder per movie
│   ├── The Matrix (1999)/
│   │   ├── The Matrix.mp4
│   │   └── poster.jpg             ← optional artwork
│   └── Lord of the Rings Extended/
│       ├── Part 1.mkv             ← several videos = one movie, played in order
│       └── Part 2.mkv
├── Shows/                         ← one folder per show
│   └── The Office/
│       ├── fanart.jpg             ← optional artwork
│       ├── Season 1/              ← one folder per season
│       │   ├── S01E01 Pilot.mp4
│       │   └── S01E02 Diversity Day.mp4
│       └── Season 2/
│           └── S02E01 The Dundies.mp4
└── Other/                         ← photos and home videos for slideshows
    └── Summer 2025/
        ├── IMG_0001.jpg
        ├── VID_0002.mp4
        └── Day trip/              ← subfolders are fine here
```

You don't need all three folders. Anything else on the drive is ignored by the Movies and Shows rows, and can still be opened from **Browse → Files**.

## 1. Prepare the drive

- **Which Roku:** you need a Roku with a USB port: most Roku TVs, the Roku Ultra, and some older players. Streaming sticks have no USB port.
- **Format:** Roku reads drives formatted as **NTFS**, **FAT32**, **exFAT** (most current models), **HFS+** (Mac) and **ext2/ext3** (Linux). A drive formatted on Windows as **NTFS** or **exFAT** is the easy choice. FAT32 works but can't hold a file larger than 4 GB, so long HD movies won't fit. If the TV doesn't see your drive, check Roku's support pages for your model's list.
- **Size:** any size the TV can power. Large hard drives without their own power supply may draw too much; use a powered hub or a drive with its own adapter if the TV doesn't detect it.
- **Several drives** work at once. If two drives each have a `Movies` folder, you see one combined list. A show split across drives (Season 1 on one, Season 2 on the other) is merged too, as long as the show folders have exactly the same name.

## 2. The three top-level folders

Create them at the **very top** of the drive, not inside another folder. Upper/lower case doesn't matter (`movies`, `MOVIES` and `Movies` all work).

| Folder | What goes in it | Shows up as |
|---|---|---|
| `Movies` | A folder per movie | The **Movies** row and **Browse → All Movies** |
| `Shows` | A folder per show, with season folders inside | The **Shows** row and **Browse → All Shows** |
| `Other` | Any folders of photos and videos | **Browse → Other**, played as slideshows |

## 3. Movies

```
Movies/
  Inception (2010)/
    Inception.mkv
  The Godfather/
    The Godfather.mp4
    fanart.jpg
  Lord of the Rings Extended/
    Part 1.mkv
    Part 2.mkv
```

- **Every movie needs its own folder.** The folder name is the title on the TV ("Inception (2010)"). The video file's own name doesn't matter.
- **One video file** in the folder = a normal movie.
- **Several video files** in the folder = one movie in parts, played one after another in name order ("Part 1", "Part 2", … "Part 10"). Don't put two different movies in the same folder.
- Only videos **directly** in the movie's folder are used. Put extras in a subfolder (for example `Extras/`) and they're left out of the movie; you can still play them from **Browse → Files**.

## 4. Shows

```
Shows/
  Breaking Bad/
    Season 1/
      Breaking Bad S01E01.mkv
      Breaking Bad S01E02.mkv
    Season 2/
      Breaking Bad S02E01.mkv
    Specials/
      Behind the scenes.mp4
  Planet Earth/
    01 From Pole to Pole.mp4       ← no season folders: one list called "Episodes"
    02 Mountains.mp4
```

- **Every show needs its own folder** inside `Shows`. The folder name is the title on the TV.
- **Inside the show, one folder per season.** The season folder's name is shown as is (`Season 1`, `Series 2`, `Specials`, …) and seasons are ordered naturally, so `Season 2` comes before `Season 10`.
- A show with only one season, or a mini-series, can skip season folders: videos placed directly in the show folder appear as a season called **Episodes**.
- Only one level of season folders is read. Don't nest deeper (`Season 1/Disc 1/…`): those episodes won't appear.
- **Episode order:** files with an episode code, `S01E02` or `1x02`, anywhere in the name are ordered by that code. Otherwise they're ordered by name, naturally (`Episode 2` before `Episode 10`). Starting names with a number (`01`, `02`, …) is a simple way to get the right order.
- The episode code is also how Couchmark names the episode on screen (`S01E02`), so it's worth keeping.

## 5. Other (photos and home videos)

```
Other/
  Summer 2025/
    IMG_0001.jpg
    IMG_0002.jpg
    VID_0003.mp4
    Day trip/
      IMG_0100.jpg
  Grandma's 80th/
    DSC_1234.jpg
```

- Make any folders you like, nested as deep as you like. On the TV you browse into them, and every folder with photos or videos has a **Play slideshow** row at the top.
- A slideshow plays the photos and videos **directly in that folder**, not its subfolders. Open `Day trip` to play that one.
- Items play **in the order they were taken**, using the date the camera stored in the photo or video, so file names don't matter. Files without that date (edited exports, some video formats) use the file's modified date.

## 6. Artwork (optional)

Put an image in a movie or show folder and Couchmark uses it for the tile and as the page background:

```
Movies/The Matrix (1999)/fanart.jpg
Shows/The Office/poster.png
```

It looks for these names, in this order: `fanart`, `landscape`, `backdrop`, `poster`, `folder`, `cover`, `thumb`, ending in `.jpg`, `.jpeg` or `.png` (upper/lower case doesn't matter). Wide 16:9 images look best. These are the names Kodi, Plex and Jellyfin use, so an existing library usually works as is. Titles without artwork get a plain card with their name.

## 7. Supported files

| Type | Extensions |
|---|---|
| Video | `.mp4` `.m4v` `.mov` `.mkv` `.ts` `.webm` |
| Photo | `.jpg` `.jpeg` `.png` `.gif` `.bmp` |

- Roku plays files as they are, with no converting. The safest choice is **H.264 or H.265 video with AAC or AC3 audio, in an MP4 or MKV file**. Other codecs depend on your Roku model.
- **HEIC photos** (the iPhone's default) are not supported. Convert them to JPEG, or set the iPhone to *Settings → Camera → Formats → Most Compatible* before taking them.
- Subtitle files (`.srt`) are ignored for now.
- Hidden and system files (`.DS_Store`, `._*`, `Thumbs.db`, `$RECYCLE.BIN`, …) are always ignored.

## Common mistakes

| You did | What happens | Fix |
|---|---|---|
| `Movies/Inception.mkv` (no movie folder) | The movie doesn't appear | Move it into `Movies/Inception/Inception.mkv` |
| `Shows/S01E01.mp4` (no show folder) | The episode doesn't appear | Make a folder per show: `Shows/The Office/S01E01.mp4` |
| `Media/Movies/…` (not at the top) | Nothing under it appears in the Movies row | Move `Movies` to the top of the drive |
| Two movies in one movie folder | They play as one movie in two parts | Give each movie its own folder |
| `Shows/X/Season 1/Disc 1/…` | Those episodes don't appear | Keep episodes directly in the season folder |
| Renamed a movie or show folder | Its watch progress starts over | Progress is saved by folder name; rename it back to recover it |
| A `.avi`, `.wmv` or `.heic` file | Not listed, or shown as **Can't play** in Files | Convert it to MP4 / JPEG |

If something still doesn't appear, open **Browse → Files** on the TV: it shows the drive exactly as Couchmark sees it. The [debug log](USER-GUIDE.md#debug-logs) also lists every file it skipped and why.

## What Couchmark writes to the drive

Nothing in your media folders: it never renames, moves or deletes your files. The only thing it creates is a `Couchmark/logs` folder with a small daily log file (at most 7 days kept). You can turn that off under **Settings → Save debug logs to USB**.

Your watch progress and settings are stored on the TV, not on the drive, so you can unplug the drive, add files on a computer and plug it back in without losing anything.
