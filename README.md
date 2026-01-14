# GuitarMax 🎸

An iOS app that teaches you guitar chords using real-time computer vision and hand tracking. Point your camera at your guitar, and GuitarMax will guide your finger placement with instant visual feedback.

## Features

### 🎯 Real-Time Finger Tracking
- Uses Vision framework to detect hand positions and fingertips
- Provides instant feedback on finger placement accuracy
- Color-coded indicators (green = correct, red = incorrect, orange = missing)

### 🎸 Smart Guitar Detection
- **Automatic Mode**: AI-powered guitar neck and string detection using computer vision
- **Manual Mode**: Precise 4-step calibration system for custom guitar positioning
- Real-time tracking with heavy smoothing for stable detection

### 📚 Chord Library
Currently supports 8 essential beginner chords:
- **Major Chords**: C, D, E, G, A
- **Minor Chords**: Am, Em, Dm

### 🎨 Interactive UI
- Live camera feed with augmented reality overlays
- Chord diagrams with finger position indicators
- Visual fret and string guidelines
- Step-by-step calibration interface

### 🔊 Audio Detection
- Real-time audio monitoring (basic implementation)
- Microphone permission handling
- Ready for pitch detection integration

## How It Works

### Guitar Orientation
The app is designed for **landscape mode** with the phone positioned horizontally (volume buttons down):

```
        Nut          Fret 1       Fret 2       Fret 3       Fret 4
        ↓            ↓            ↓            ↓            ↓
String 6 (Low E)  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        |            |            |            |            |
String 5 (A)      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        |            |            |            |            |
String 4 (D)      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        |            |            |            |            |
String 3 (G)      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        |            |            |            |            |
String 2 (B)      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        |            |            |            |            |
String 1 (High e) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

- **Frets**: Run horizontally (top to bottom)
- **Strings**: Run vertically (left to right)
- **Coordinate System**: Uses real guitar physics (12-tone equal temperament) for accurate fret positioning

### Computer Vision Pipeline

1. **Camera Setup**
   - Front-facing camera in landscape orientation
   - 90° rotation handling for proper coordinate mapping
   - Video mirroring for natural user experience

2. **Guitar Neck Detection** (Auto Mode)
   - Rectangle detection to identify guitar neck boundaries
   - Contour detection for string line identification
   - Multi-frame smoothing for stable tracking
   - Validates string spacing and regularity

3. **Hand Tracking**
   - VNDetectHumanHandPoseRequest for finger detection
   - Tracks index, middle, ring, and pinky fingertips
   - Confidence-based filtering (>0.3 threshold)
   - Real-time coordinate conversion from Vision to screen space

4. **Finger Position Analysis**
   - Calculates expected finger positions based on chord definition
   - Compares detected fingertips with target positions
   - Distance-based accuracy checking (8% tolerance)
   - Dynamic updates as guitar position changes

## Technical Architecture

### Core Components

- **AudioManager**: Handles microphone access and audio buffer processing
- **CameraManager**: Manages camera session and delegates to GuitarNeckTracker
- **GuitarNeckTracker**: Computer vision pipeline for guitar detection
- **GuitarZone**: Data model representing calibrated guitar coordinate space
- **GuitarChord**: Chord definitions with finger positions

### Key Technologies

- **Vision Framework**: Hand pose detection and contour analysis
- **AVFoundation**: Camera and audio capture
- **Core Image**: Edge detection and image processing
- **SwiftUI**: Reactive UI with real-time updates
- **Combine**: Observable objects for data flow

## Requirements

- iOS 14.0+
- iPhone with front-facing camera
- Microphone and camera permissions
- Physical guitar

## Usage

1. Launch the app and grant camera/microphone permissions
2. Position your phone horizontally (volume buttons down)
3. Select a chord from the dropdown menu
4. Choose **Auto** for automatic detection or **Manual** for calibration
5. Press **Start Lesson**
6. Position your fingers on the guitar neck
7. Follow the color-coded feedback:
   - **Green circles**: Fingers correctly placed ✓
   - **Red circles**: Fingers in wrong position ✗
   - **Orange circles**: Fingers not detected ?

## Future Enhancements

- [ ] Pitch detection and strumming analysis
- [ ] Progress tracking and practice statistics
- [ ] More advanced chords (bar chords, 7ths, suspended, etc.)
- [ ] Custom chord creation
- [ ] Song learning mode with chord progressions
- [ ] Multi-guitar support (acoustic, electric, bass)
- [ ] Practice exercises and drills
- [ ] Social features and sharing

## Known Limitations

- Requires good lighting conditions for optimal detection
- Works best with standard guitar neck dimensions
- String detection accuracy varies with guitar finish and lighting
- Hand tracking requires clear view of fretting hand
- Currently detects only one hand at a time

## License

MIT License - feel free to fork and modify!
