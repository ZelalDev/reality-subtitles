# Duy Beni

An early-stage project exploring real-time Turkish subtitles, with a SwiftUI iOS app and research into audio-visual speech recognition.

The current iOS app records audio and transcribes it into Turkish after recording stops, using WhisperKit with a user-selected multilingual Tiny or Base model and an explicit Turkish language setting (`tr`). Live transcription and visual speech recognition are planned work.

## App demo

<p align="center">
  <img src="docs/media/ios-app-demo.gif" alt="Duy Beni iOS app demo" width="300">
</p>

## Current status

| Component | Available today |
| --- | --- |
| iOS app | Microphone access, start/stop recording, temporary audio capture, and Turkish transcription after recording stops |
| Web prototype | Turkish speech-to-text using the browser Web Speech API |
| Research | Initial notes on speech recognition, datasets, and audio-visual approaches |

## Run the iOS app

1. Clone this repository and open `ios/RealitySubtitles.xcodeproj` in Xcode.
2. Select the **RealitySubtitles** scheme and an iPhone simulator or connected iPhone.
3. For a physical device, select your signing team in **Signing & Capabilities**.
4. Run the app, select **Whisper Tiny** or **Whisper Base**, allow microphone access, and use **Kaydı Başlat** / **Kaydı Durdur** to record audio. After stopping, wait for the Turkish transcript to appear. The first transcription requires an internet connection to download the selected model. Your selection is saved between launches; model selection is disabled during recording and transcription.

The project currently targets **iOS 27.0** and was verified with **Xcode 27.0**. Audio is captured in the app's temporary directory and deleted after transcription, including on failure. Interrupted recordings are cleaned up on the next launch. Older audio in `Documents/recording.m4a` and `Documents/BenchmarkRecordings` is removed on startup.

Build verification: the complete app, including the model selector and Lip Reading screens, built successfully for a generic iOS device with Xcode 27.1 and code signing disabled. Camera tracking and transcription with both models still need physical-device verification.

## Model selection

The app offers exactly two models: **Whisper Tiny** (`openai_whisper-tiny`) and **Whisper Base** (`openai_whisper-base`). Both use Turkish decoding (`tr`). Tiny is the default. Changing the selection loads the chosen model on the next transcription and releases the previous model from the transcriber.

The app does not measure processing time or write/export benchmark CSV results. Temporary audio is deleted after processing, including on failure.

## Lip Reading (face and lip detection)

The home screen offers **Speech-to-Text** (the existing transcription screen) and **Lip Reading**. Lip Reading uses the rear camera and Apple Vision to outline the lips of the largest visible face in green. It does not predict words or include a lip-reading AI model.

Tap **Kamerayı Başlat** to request camera permission and begin the preview. **Durdur**, leaving the screen, or moving the app to the background stops capture and analysis. After a background transition or camera interruption, tap Start again. Denied permission shows an explanation and a Settings button.

Camera frames are processed only in memory. This feature has no photo/video file output, cache, database, or network upload. A serial background queue runs Vision at most eight times per second, discards late frames, and releases each frame's processing objects after analysis. Only lip coordinates, image dimensions, and the latest rendered 96×96 lip crop are sent to the UI. A small preview below the camera shows the crop live. Crops use a square region with a small margin, preserving proportions, and are rendered as sRGB RGBA8 images. A timestamped RAM buffer retains at most 16 frames and less than two seconds of samples, oldest first. Detection loss or camera stop clears the buffer and preview. Full camera frames are never retained in this buffer. No model inference is performed. The existing speech recording and transcription flow is separate.

Physical-device verification checklist:

- Grant camera permission, start the camera, and confirm the rear-camera preview.
- Move a face and lips in/out of view; check the green outline and both detection labels.
- Check that the 96×96 preview follows the same lips as the green outline, including near image edges.
- Hide the face and stop/restart repeatedly; confirm both the crop and outline clear and the camera indicator turns off when stopped.
- Leave the screen, lock the phone, or background the app during capture or the permission prompt; verify capture stops and does not automatically restart.
- Deny camera permission, then enable it in Settings and retry.
- Test a camera interruption and verify that restarting works.
- Open Speech-to-Text and transcribe with both existing model options.
- Profile memory and CPU on a real device during a prolonged session; confirm memory does not grow with captured frames.

## Explore the repository

```text
reality-subtitles/
├── README.md
├── ios/
│   ├── RealitySubtitles/
│   ├── RealitySubtitles.xcodeproj/
│   ├── RealitySubtitlesTests/
│   └── RealitySubtitlesUITests/
├── demo/
│   └── index.html
└── docs/
    ├── project/
    └── progress/
        ├── week-01/
        ├── week-02/
        ├── week-03/
        └── week-04/
```

- **[iOS app](ios/)** — current native application and its Xcode project.
- **[Web prototype](demo/index.html)** — the initial Turkish subtitle experiment. Open it in a browser supporting the Web Speech API and allow microphone access; support varies by browser.
- **[Week 1 research](docs/progress/week-01/Reality%20Subtitles%201.%20week.pdf)** — the original project notes, preserved for reference.
- **[Week 2 report](docs/progress/week-02/week-02-report.pdf)** — the second weekly progress report.
- **Week 3 documents** — [Document 2](docs/progress/week-03/week%203%20%282%29.pdf) and [Document 3](docs/progress/week-03/week%203%20%283%29.pdf).

- **[Week 4 report](docs/progress/week-04/week-04-report.pdf)** — model selection, Duy Beni branding, lip detection, and in-memory lip-frame preparation.

## Project documents

These Turkish-language documents describe the initial proposal and planned scope. They are planning references, not a record of implemented features or completed experiments. The current implementation status is listed above.

| Document | Purpose |
| --- | --- |
| [Project proposal (PDF)](docs/project/project-proposal.pdf) | Research question, proposed method, scope, and expected outputs |
| [Six-month plan (Word)](docs/project/six-month-plan.docx) | 24-week plan, milestones, evaluation approach, and risks |
| [Long-term vision (Word)](docs/project/long-term-vision.docx) | Future product directions beyond the initial iOS scope |

Crop and buffer checks (macOS):

```sh
xcrun swiftc ios/RealitySubtitles/LipFrameBuffer.swift tests/LipFrameBufferChecks.swift -o /tmp/lip-frame-checks
/tmp/lip-frame-checks
```
