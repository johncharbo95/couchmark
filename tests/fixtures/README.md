# Test fixtures

Tiny (~2 KB, 1-second) videos with known creation dates, used by `MediaDate.test.brs`. They were generated with ffmpeg:

| File | Created (UTC) | Notes |
|---|---|---|
| `moov_at_end.mp4` | 2021-07-12 14:30:00 | default layout: `moov` box after the video data |
| `faststart.mp4` | 2019-03-02 08:00:00 | `-movflags +faststart`: `moov` first |
| `quicktime.mov` | 2024-12-25 20:15:00 | QuickTime container |
| `no_date.mp4` | none | no `creation_time`, so the file date should be used |

```sh
ffmpeg -f lavfi -i color=c=blue:s=64x64:d=1 -metadata creation_time=2021-07-12T14:30:00Z -c:v libx264 moov_at_end.mp4
ffmpeg -f lavfi -i color=c=red:s=64x64:d=1 -metadata creation_time=2019-03-02T08:00:00Z -movflags +faststart -c:v libx264 faststart.mp4
ffmpeg -f lavfi -i color=c=green:s=64x64:d=1 -metadata creation_time=2024-12-25T20:15:00Z -c:v libx264 quicktime.mov
ffmpeg -f lavfi -i color=c=white:s=64x64:d=1 -c:v libx264 no_date.mp4
```
