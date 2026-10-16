# Changelog

All notable changes to this project will be listed here.

## [0.2.0] - 2026-10-16

### Added
- **MCP Support**: Integrated basic support for the Model Context Protocol (MCP).
- **User-defined Curl Args**: Added the ability to pass custom `curl` arguments to the harness.
- **Enhanced Prompt Templates**: Introduced `$@` support to handle remaining text in templates and improved argument parsing security by replacing `eval`.

### Fixed
- **Stream Compatibility**: Expanded provider support for correctly parsing streaming responses.
- **Subtask Verbosity**: Reduced the output noise from subtasks to improve overall response clarity.

## [0.1.0] - 2026-10-06
- Initial release.
