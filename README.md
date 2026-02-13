# LaunchpadPlus

LaunchpadPlus is a modern and customizable alternative application launcher for macOS, developed using Swift and SwiftUI.

## Overview

LaunchpadPlus enhances the standard macOS Launchpad experience by providing advanced customization options, dynamic sorting, and a fluid user interface designed for improved productivity.

## Primary Features

- **Full-Screen Coverage**: The interface covers the entire display, including safe areas and the screen notch, ensuring a consistent visual experience.
- **Dynamic Sorting Options**:
  - **Alphabetical**: Standard A-Z organization.
  - **Installation Date**: Sorts applications by the date they were added to the directory using system metadata.
  - **Most Used**: Ranks applications based on personal usage statistics.
  - **Manual**: Supports custom arrangements via drag-and-drop interactions.
- **Directory Observation**: Monitors system application folders in real time and automatically updates the application list when items are installed or removed.
- **Advanced Interaction**:
  - **Background Dismissal**: Clicking any empty area on the background hides the application.
  - **Keyboard Support**: Navigate using arrow keys, perform rapid character-based searches, and launch apps with the return key.
  - **Navigation**: Supports trackpad swipes, scroll wheel integration, and circular page transitions.
- **Hotkey Customization**: Includes a dedicated recording dialog to set a custom global activation shortcut with real-time feedback.
- **Single Instance Control**: Prevents multiple copies from running simultaneously to ensure stability and avoid shortcut conflicts.
- **Favorites Bar**: Provides persistent access to a selected row of favorite applications across all pages.
- **Configurable Grid**: Allows users to adjust the number of rows and columns to suit different screen sizes and preferences.
- **Application Management**: Directly manage applications, including the ability to toggle system utilities and move items to the Trash.

## Technical Specifications

- **Development Environment**: Swift 5.9 or newer.
- **Architecture**: Hybrid structure using SwiftUI for the user interface and AppKit for window and system event management.
- **Monitoring Infrastructure**: Uses FSEvents to observe file system changes in background threads.
- **Data Persistence**: Settings, usage counts, and custom configurations are managed via UserDefaults.
- **System APIs**: Integration with Carbon for global hotkey handling and NSWorkspace for low-level application interactions.

## Installation

### From Source

1. Clone the repository to the local machine.
2. Build the project using the command: `swift build -c release`.
3. Package the application by executing the script: `bash bundle_app.sh`.

## Contributing

Professional contributions are welcome. Please utilize the standard repository fork and pull request workflow for any proposed changes.

## License

This project is licensed under the MIT License. Detailed information is available in the LICENSE file.

---
Development is focused on modern macOS design principles and efficient application management.
