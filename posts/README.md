# Blog Posts

This directory contains all blog posts for the website.

## How to Add a New Blog Post

1. Create a new Markdown file with the naming convention: `YYYY-MM-DD-title.md`
   - Example: `2025-04-15-javascript-tips.md`

2. Add your post content in Markdown format.

3. Update the `index.json` file by adding a new entry:
   ```json
   {
     "title": "Your Post Title",
     "date": "YYYY-MM-DD",
     "id": "YYYY-MM-DD-title"
   }
   ```

## File Structure

- `index.json` - Contains metadata for all blog posts
- `*.md` - Individual blog post content files

All posts will be automatically loaded and displayed on the website. 