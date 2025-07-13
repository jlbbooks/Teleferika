# Version Bump Automation Prompt

Use this prompt to automate the complete version bump process:

## Prompt Template

```
Please increase the version number for this Flutter project. I want you to:

1. **Analyze changes since last tag:**
   - Get the latest git tag
   - Check what commits have been made since that tag
   - Identify which files have been modified
   - Understand the scope and nature of changes

2. **Update version number:**
   - Increment the version in pubspec.yaml (e.g., 0.9.30+71 → 0.9.31+72)
   - Use semantic versioning: patch for docs/bugfixes, minor for features, major for breaking changes

3. **Update CHANGELOG.md:**
   - Add new version entry at the top with today's date
   - Organize changes into Added, Changed, Fixed, Technical sections
   - Keep previous entries intact
   - Base descriptions on actual git commits and file changes

4. **Generate commit with descriptive message:**
   - Create a commit message that summarizes the actual changes since last tag
   - Use conventional commit format (feat:, fix:, docs:, etc.)
   - Include key changes and improvements made

5. **Create git tag:**
   - Create an annotated tag with the new version number
   - Include a short summary of the main changes

6. **Generate Play Store changelog:**
   - Create changelog in format: <en-GB>English text</en-GB><it-IT>Italian text</it-IT>
   - Use plain text (no Markdown)
   - Keep it concise and user-friendly
   - Focus on user-visible improvements
   - Include newlines after each opening and closing language tag for proper XML formatting

7. **Commit all changes:**
   - Stage and commit pubspec.yaml version change
   - Stage and commit CHANGELOG.md update
   - Create the git tag

Please analyze the actual changes made since the last tag and generate appropriate descriptions based on the real modifications, not assumptions.
```

## Expected Output

The assistant should:
- Show analysis of current state (latest tag, commits since tag, files changed)
- Generate appropriate version number
- Create descriptive commit message based on actual changes
- Update CHANGELOG.md with proper entries
- Generate Play Store changelog in correct format
- Execute all git commands to commit and tag

## Key Requirements

- **Analyze real changes:** Don't assume, check actual git history
- **Appropriate versioning:** Use semantic versioning based on change type
- **Descriptive messages:** Base descriptions on actual commits and file modifications
- **Complete automation:** Handle all steps from analysis to final commit
- **Proper formatting:** Use correct formats for each artifact (commit, tag, changelog, Play Store)

## Usage

Simply ask: "Please increase the version number" and the assistant should execute this entire process automatically. 