# Generate .gitignore

Analyse the repository and generate a precise .gitignore file. Only add concrete, evidenced entries — no speculative boilerplate.

## Process

1. Check whether a .gitignore already exists
2. Analyse the repository
3. Determine entries
4. Confirm with user
5. Write the file

## Step 1: Check Existing .gitignore

If a .gitignore exists, read it. Note what is already covered so you do not duplicate entries.

## Step 2: Analyse the Repository

Examine the repository to identify what should be ignored:

- Language and framework indicators: look for go.mod, package.json, Cargo.toml, requirements.txt, Gemfile, etc.
- Build outputs: check for build/, dist/, target/, bin/ directories or compiled artifacts
- IDE and editor files: look for .vscode/, .idea/, *.swp, etc.
- Tool files: .env, local config overrides, credentials, lock files that should not be committed
- OS-specific files: .DS_Store, Thumbs.db, desktop.ini
- Run `git status --short` to see what is currently untracked and why

Focus on what is actually present. Do not add entries for tools or languages not in use.

## Step 3: Determine Entries

For each entry, apply path precision:

- Use a leading `/` for items that only exist at the repository root (e.g., a binary `/foo` produced by `./cmd/foo`, not `foo` which would also ignore the source directory)
- Use a trailing `/` for directories (e.g., `dist/`)
- Use unrooted patterns only when the entry genuinely applies at any depth in the tree (e.g., `*.log`, `*.swp`)
- Do not duplicate entries already in the existing .gitignore

## Step 4: Confirm with User

Present the proposed entries grouped by category (e.g., build outputs, IDE, OS). Explain the reasoning for any non-obvious entry. Ask the user to confirm before writing.

## Step 5: Write the File

Write or update .gitignore with the confirmed entries. Use comments to group entries by category:

```
# Build outputs
/myapp

# IDE
.idea/
.vscode/

# OS
.DS_Store
```

If updating an existing file, append new entries after the existing content with a blank line separator.
