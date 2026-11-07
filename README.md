# TV Photo Slideshow

A flashy, self-contained photo and video slideshow for **Android TV and Fire TV**. Your pictures and videos are packed
inside the app, so it runs with no PC or network. It is a tiny native shell around a full-screen web page.

## What it does

- Shuffled slideshow of photos and videos with a blurred backdrop, slow pan-and-zoom and nine different transitions.
- Portrait photos sometimes appear as three-photo collages, and the date shows as a caption.
- **Galaxy scene.** Every few slides, thumbnails swirl like stars in a spiral galaxy, then the camera dives into one at
  random and gives it a funny caption.
- Funny captions on about half the photos.
- **Museum plaques** on photos you choose (see `app/assets/plaques.js`).
- **Tagged photos** (see `app/assets/tagged.js`) always get a playful roast caption. Handy for teasing a friend who is in
  too many pictures.
- Starts automatically when the TV boots. On Android 10 and later you may need to grant the app **Display over other
  apps**: `adb shell appops set com.example.photoslideshow SYSTEM_ALERT_WINDOW allow`.
- Remote control: left/right skip, OK or play/pause pauses, up shows file info, down changes the speed.

## Build it

You need Windows with PowerShell, plus these in `%LOCALAPPDATA%\FireTVBuild` (a short path avoids Windows' 260 character limit):

- `jdk\` - an unzipped JDK 17
- `sdk\` - the Android SDK with `platforms;android-34`, `build-tools;34.0.0` and `platform-tools`
  (install them with the SDK's `sdkmanager`)

No Gradle or Android Studio is needed. Then:

1. **Prepare your media.** This converts HEIC, PNG and JPG to TV-sized JPEGs and copies videos:
   ```powershell
   .\tools\prepare-media.ps1 -Source "C:\Path\To\Your\Photos"
   .\tools\make-thumbs.ps1
   ```
   This creates `app/assets/media/`, `app/assets/thumbs/` and `app/assets/media.js`. They are git-ignored, so your photos
   never end up in the repo.
2. **Optional: personalize.**
   - Replace `app/assets/logo.jpg` (600x600) with your own title-screen image. It is also used for the launcher banner.
   - Edit `app/assets/plaques.js` to add museum plaques.
   - Run `.\tools\serve.ps1`, open `http://localhost:8765/tagger.html`, click photos to tag them, press **Copy tagged.js**
     and paste the result into `app/assets/tagged.js`.
3. **Build:**
   ```powershell
   .\build.ps1
   ```
   This produces `PhotoSlideshow.apk`, signed with a local debug key.
4. **Install** on the TV (enable ADB debugging in the TV's developer options first):
   ```
   adb connect <tv-ip>:5555
   adb install PhotoSlideshow.apk
   ```

Preview in a desktop browser with `.\tools\serve.ps1`, then open `http://localhost:8765/`. Add `?galaxy=2` to see the
galaxy scene after two slides.

## Notes

- Tested on an Android 14 TV box. Very old Fire TV sticks use an older browser engine and may animate less smoothly.
- Everything is local: nothing is uploaded and there is no network access.
- No license has been chosen yet. Add one if you want others to reuse the code.
