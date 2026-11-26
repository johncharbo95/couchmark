# Installing Couchmark on your Roku

Couchmark isn't in the Roku Channel Store. You install it yourself through the Roku's **developer mode**, which every Roku has built in. It's free, needs no special software, and takes about ten minutes the first time. After that, updating takes one minute.

## What you need

- A **Roku with a USB port** (most Roku TVs, Roku Ultra). Streaming sticks have no USB port.
- A **computer** (Windows, Mac or Linux) with a web browser, on the **same network** as the Roku.
- The Roku **connected to the internet**, signed in to a Roku account as usual.
- A **USB drive** with your movies, shows or photos. See [Setting up your USB drive](USB-SETUP.md).

## Step 1: Turn on developer mode (one time)

1. On the Roku remote, press this sequence, at a steady pace:

   **Home Home Home  ·  Up Up  ·  Right Left Right Left Right**

2. A **Developer Settings** screen appears. Write down the **IP address** it shows (for example `192.168.1.50`).
3. Choose **Enable installer and restart**, then accept the developer agreement.
4. Pick a **password** (you'll type it on the computer in step 3). The Roku restarts.

If nothing happens, press **Home** a few times to get to the Roku home screen and try the sequence again. You can always look up the IP address later under **Settings → Network → About**.

Developer mode doesn't change anything else on the Roku: your other channels, account and settings stay as they are.

## Step 2: Download Couchmark

1. Open the [Releases page](https://github.com/johncharbo95/couchmark/releases) and pick the newest version at the top.
2. Under **Assets**, download **`couchmark-vX.Y.Z.zip`** (the numbers are the version).
3. **Don't unzip it.** The Roku wants the zip file as it is. (Some browsers, like Safari on a Mac, unzip downloads automatically. If you end up with a folder instead of a `.zip` file, turn that off in the browser settings and download again.)

New to Couchmark? Also download **`couchmark-usb-starter.zip`**. Unzip that one onto your USB drive to get the `Movies`, `Shows` and `Other` folders.

## Step 3: Upload it to the Roku

1. On the computer, open a browser and go to `http://` followed by the Roku's IP address, for example **`http://192.168.1.50`**. (Type `http://`, not `https://`.)
2. Sign in with user name **`rokudev`** and the password from step 1.
3. On the **Development Application Installer** page, click **Upload** and choose the `couchmark-vX.Y.Z.zip` file.
4. Click **Install with zip** (or **Install**, depending on the Roku's software version).

Couchmark starts on the TV straight away. It's now on the Roku home screen as a channel, so next time just open it like any other channel.

## Step 4: Plug in the USB drive

Plug the drive into the Roku's USB port, before or after opening Couchmark. Couchmark notices drives being plugged in and removed, and your movies and shows appear on its home screen within a few seconds. Then see [Using Couchmark](USER-GUIDE.md).

## Updating to a new version

1. Download the new `couchmark-vX.Y.Z.zip` from the [Releases page](https://github.com/johncharbo95/couchmark/releases).
2. Open `http://<roku-ip>` again, click **Upload**, choose the new zip, and click **Replace with zip** (or **Install**).

Your watch progress, ✓ marks and settings are kept when you install over the old version.

> **Don't click Delete** on the installer page. Deleting the app also erases everything it saved on the TV: all watch progress and settings. Installing a new version over the old one is all an update needs.

You can see which version is installed under **Browse → Settings** in Couchmark.

## Good to know

- **Only one sideloaded app** can be installed on a Roku at a time. Installing a different developer app replaces Couchmark (and erases its watch progress).
- Couchmark **stays installed** when the Roku restarts or updates its software.
- A **factory reset**, or turning developer mode off, removes Couchmark and its watch progress. To turn developer mode off on purpose, repeat the remote sequence and choose **Disable installer and restart**.
- Nothing is sent to the internet. Couchmark only reads your USB drive and stores its progress on the TV.

## Troubleshooting

| Problem | Try this |
|---|---|
| The remote sequence does nothing | Start from the Roku home screen, press the buttons steadily (not too fast), and use the physical remote (some phone remote apps don't work). |
| The browser can't open `http://<roku-ip>` | Check the computer and Roku are on the same network (not a guest Wi-Fi), the address starts with `http://`, and the IP is current (**Settings → Network → About**; it can change after a router restart). |
| The sign-in keeps failing | The user name is `rokudev`. If you forgot the password, repeat the remote sequence: the Developer Settings screen lets you set a new one. |
| "Install failure" or "manifest not found" | The file was unzipped or is the wrong one. Upload the `couchmark-vX.Y.Z.zip` from **Assets**, not "Source code (zip)". |
| Couchmark says "No USB drive" | Check the drive's format and power in [Setting up your USB drive](USB-SETUP.md#1-prepare-the-drive), and try the other USB port if the TV has two. |
| A movie or show is missing | See [Common mistakes](USB-SETUP.md#common-mistakes), or open **Browse → Files** to see what Couchmark finds on the drive. |
| Something else goes wrong | Look at the [debug log](USER-GUIDE.md#debug-logs) on the USB drive, and [open an issue](https://github.com/johncharbo95/couchmark/issues) with the relevant lines. |

## For developers: build and install from the source code

You only need this to change Couchmark or try unreleased work. It needs [Node.js](https://nodejs.org/) 22 or newer.

```sh
git clone https://github.com/johncharbo95/couchmark.git
cd couchmark
npm install
```

Then either:

- **Build the same files as a release:** `npm run dist` writes `out/release/couchmark-vX.Y.Z.zip` (upload it as in step 3), the USB starter zip and checksums.
- **Install straight from a terminal:** copy `.env.example` to `.env`, fill in the Roku's IP address and developer password, then run `npm run deploy`. It builds and installs over the current version, keeping watch progress.

Every push to GitHub also builds these files: open the run under the repository's **Actions** tab and download them under **Artifacts**.

See [DEVELOPMENT.md](DEVELOPMENT.md) for the full developer guide.
