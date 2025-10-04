# Apple Signing Workflow Task List

## Keychain Management

**Task:** Promote temporary keychain to default _(SCRUM-1)_
- [ ] _(SCRUM-4)_ Call `security default-keychain -s "$KEYCHAIN_PATH"` right after keychain creation
- [ ] _(SCRUM-5)_ Apply `security set-keychain-settings -t 3600 -u "$KEYCHAIN_PATH"`
- [ ] _(SCRUM-6)_ Persist `$KEYCHAIN_PATH` and `$KEYCHAIN_PASSWORD` using `$GITHUB_ENV`
- [ ] _(SCRUM-7)_ Keep the keychain unlocked through the signing steps and clean up afterward

**Task:** Preserve keychain search list and identity discovery _(SCRUM-2)_
- [ ] _(SCRUM-8)_ Append the temporary keychain to the existing `security list-keychains` output instead of replacing it
- [ ] _(SCRUM-9)_ Add a guard that fails the job when `security find-identity -p codesigning` finds no Developer ID identity
- [ ] _(SCRUM-10)_ Export the selected identity string to `$GITHUB_ENV` for downstream steps

## Security Hygiene

**Task:** Remove sensitive logging in macOS signing step _(SCRUM-3)_
- [ ] _(SCRUM-11)_ Delete debug `echo` statements that reveal secret presence or values
- [ ] _(SCRUM-12)_ Audit the workflow for any additional signing-related logs that could leak secrets
- [ ] _(SCRUM-13)_ Update contributor notes/PR description to explain that secret verification happens locally

---
**Jira References**
- SCRUM-1 — Fix macOS keychain initialization in release workflow
- SCRUM-2 — Restore keychain search list and validate identity detection
- SCRUM-3 — Remove sensitive secret logging from release workflow
