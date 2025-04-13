# Blog Directory

This directory contains all blog posts for the website.

## How to Add a New Blog Post

1. Create a new Markdown file with the naming convention: `YYYY-MM-DD-title.md`
   - Example: `2025-04-15-javascript-tips.md`

2. Add your post content in Markdown format.

3. Run the update script to regenerate the `index.json` file:
   ```powershell
   .\scripts\update-index.ps1
   ```

## File Structure

- `index.json` - Contains metadata for all blog posts
- `*.md` - Individual blog post content files
- `*.html` - HTML wrappers for each blog post

All posts will be automatically loaded and displayed on the website. 