# POC — Glaucoma Screening Research

An iOS proof-of-concept application for glaucoma screening research, built with SwiftUI and managed using XcodeGen.

## Requirements

Before getting started, make sure you have:

- A Mac running macOS.
- [Xcode](https://developer.apple.com/xcode/) installed.
- A GitHub account with access to the project repository.
- [Homebrew](https://brew.sh/) installed.
- XcodeGen installed.

## 1. Install Homebrew

Homebrew is a package manager for macOS that allows you to install development tools easily.

Open Terminal and run the following command:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Follow the instructions displayed in Terminal. If the installer asks you to configure your shell environment, follow its instructions.

Verify that Homebrew is installed:

```bash
brew --version
```

If a version number appears, Homebrew is ready to use.

Official documentation: https://brew.sh/

## 2. Install XcodeGen

XcodeGen generates an Xcode project from a YAML configuration file (`project.yml`).

Install it using Homebrew:

```bash
brew install xcodegen
```

Verify the installation:

```bash
xcodegen --version
```

If a version number appears, XcodeGen is installed successfully.

## 3. Clone the Repository

Open Terminal and navigate to the directory where you want to store the project. For example:

```bash
cd ~/Documents/ACADEMY
```

Clone the repository:

```bash
git clone https://github.com/P7K-ADA/POC.git
```

Navigate into the project directory:

```bash
cd POC
```

> Make sure you have access to the GitHub repository before cloning it.

## 4. Generate the Xcode Project

This project uses XcodeGen to generate the `.xcodeproj` file from `project.yml`.

From the repository root directory, run:

```bash
xcodegen generate
```

After generation completes, open the project:

```bash
open POC.xcodeproj
```

You can now build and run the application using Xcode.

**Important:** Whenever `project.yml` changes, run `xcodegen generate` again before building the project.

## 5. Build and Run the App

1. Open `POC.xcodeproj` in Xcode.
2. Select the `POC` scheme.
3. Choose an iOS Simulator or a connected iPhone as the run destination.
4. Press `⌘B` to build the project.
5. Press `⌘R` to run the application.

If the project fails to build, check that Xcode and XcodeGen are installed and that the project has been generated successfully.

## 6. Commit Changes Using Xcode

Use Xcode's built-in Source Control interface to commit your changes.

1. Open the project in Xcode.
2. Make your code or configuration changes.
3. Open **Source Control → Commit**.
4. Review the changed files.
5. Enter a descriptive commit message, for example:

   `Add initial camera capture screen`

6. Click **Commit** to save the changes locally.

Before committing, review the files to ensure you are not including temporary files, personal settings, credentials, or research data that should not be shared.

## 7. Push Changes to GitHub

After committing:

1. Open **Source Control → Push** in Xcode.
2. Select the appropriate remote and branch if prompted.
3. Confirm the push.

Your committed changes will be uploaded to GitHub.

If the push fails, verify that the GitHub remote is configured and that your account has permission to push to the repository.

## 8. Pull the Latest Changes

Before starting work, synchronize your local project with the team's latest changes.

In Xcode, use **Source Control → Pull**.

Resolve any merge conflicts before continuing your work.

## 9. Project Structure

```text
POC/
├── POC/
│   ├── Assets.xcassets/
│   ├── ContentView.swift
│   └── POCApp.swift
├── POC.xcodeproj/
├── project.yml
├── .gitignore
└── README.md
```

- `POC/`: Swift source files and app assets.
- `POC.xcodeproj/`: Xcode project used to build and run the app.
- `project.yml`: XcodeGen configuration.
- `.gitignore`: Specifies files Git should ignore.
- `README.md`: Project setup and development instructions.

## Development Notes

- Keep `project.yml` updated when changing project-level settings or dependencies.
- Run `xcodegen generate` after modifying the XcodeGen configuration.
- Use descriptive commit messages.
- Pull the latest changes before starting new work.
- Never commit API keys, passwords, private credentials, or identifiable patient data.
