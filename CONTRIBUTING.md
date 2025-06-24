# Contributing Guide

## Development Environment Setup

### First Time Setup

1. Install Flutter SDK: https://docs.flutter.dev/get-started/install
2. Install your preferred IDE:
   - Android Studio (recommended for Android development)
   - VS Code with Flutter extension
3. Clone this repository
4. Make scripts executable (Unix/Mac/Linux only):
   
   ```bash
   chmod +x scripts/*.sh
   ```
5. Run setup script: `./scripts/setup-opensource.sh`

### Daily Development Workflow

#### For Open Source Contributors

```bash
./scripts/setup-opensource.sh
```

Then run the app normally in your IDE

### For Team Members (with access to licensed features)

```bash
./scripts/setup-full.sh
```

Then run the app normally in your IDE