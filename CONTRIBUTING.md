# How to contribute

Thanks for your interest in contributing to Whisky-Intel! To get started:

1. Fork this repository at [jhdughrfu/Whisky-Intel](https://github.com/jhdughrfu/Whisky-Intel).
2. Create a new branch for your changes.
3. Make your changes and commit them.
4. Submit a Pull Request.

Contributions focusing on Intel architecture compatibility, universal binary optimization, runtime bug fixes, or general translation tooling are highly welcome.

# Build environment

Unlike the upstream repository, this fork supports building on:
* macOS 13.0 (Ventura) or later.
* Xcode 15.0 or later.

All external dependencies are managed through Swift Package Manager.

# Code style

Commits are automatically linted using SwiftLint. You can run checks locally by building the project in Xcode; violations will appear as errors or warnings. To merge your pull request, all checks must pass and have no violations.

Please indent your code with 4-width spaces, which can be configured in Xcode settings.

# Making your PR

Please provide a detailed description of your changes in your PR. If your commits contain user interface modifications, please include screenshots or screen recordings to demonstrate the changes.

