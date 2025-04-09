// Initialize everything when the DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    // Setup routing
    setupRouting();
    
    // Load the footer
    loadFooter();
});

// Handle routing based on URL parameters
function setupRouting() {
    // Get the URL parameters
    const params = new URLSearchParams(window.location.search);
    const postId = params.get('post');
    
    if (postId) {
        // Load a specific post
        loadPost(postId);
    } else {
        // Load the home page content
        loadHomePage();
    }
}

// Load the home page content
function loadHomePage() {
    const mainContent = document.getElementById('main-content');
    if (!mainContent) return;
    
    // Set page title
    document.title = 'Erdembayar - Personal Website';
    
    // Inject the home page content
    mainContent.innerHTML = `
        <section class="hero">
            <div class="container narrow-container">
                <h2>Erick(Erdembayar) | A computer programming blog</h2>
            </div>
        </section>

        <section class="content-section">
            <div class="container narrow-container">
                <div class="two-column-layout">
                    <div class="main-column">
                        <h2>Recent Blog Posts</h2>
                        <div class="post-grid">
                            <div class="loading">Loading posts...</div>
                        </div>
                        <div class="text-center">
                            <a href="#" class="btn" id="view-all-btn">View All Posts</a>
                        </div>
                    </div>
                    
                    <div class="side-column">
                        <div class="contact-section">
                            <h3>Contact</h3>
                            <div class="social-icons">
                                <a href="https://github.com/erdembayar" target="_blank" title="GitHub"><i class="fab fa-github"></i></a>
                                <a href="https://twitter.com/erdembayar11" target="_blank" title="Twitter"><i class="fab fa-twitter"></i></a>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>
    `;
    
    // Load the blog posts
    loadBlogPosts();
    
    // Add event listener to the "View All Posts" button
    const viewAllBtn = document.getElementById('view-all-btn');
    if (viewAllBtn) {
        viewAllBtn.addEventListener('click', function(e) {
            e.preventDefault();
            loadBlogPage();
        });
    }
}

// Load a specific blog post
function loadPost(postId) {
    const mainContent = document.getElementById('main-content');
    if (!mainContent) return;
    
    // Show loading indicator
    mainContent.innerHTML = '<div class="loading">Loading post...</div>';
    
    // Fetch post metadata from index.json
    fetch('posts/index.json')
        .then(response => {
            if (!response.ok) {
                throw new Error(`Failed to fetch posts metadata (status: ${response.status})`);
            }
            return response.json();
        })
        .then(posts => {
            // Ensure posts is an array
            const postsArray = Array.isArray(posts) ? posts : [];
            
            // Find the current post
            const currentPost = postsArray.find(post => post.id === postId);
            
            if (currentPost) {
                // Get title and date from index.json
                const title = currentPost.title;
                
                // Create date with correct timezone handling (using UTC)
                const dateParts = currentPost.date.split('-');
                const dateObj = new Date(Date.UTC(dateParts[0], dateParts[1]-1, dateParts[2]));
                
                const formattedDate = dateObj.toLocaleDateString('en-US', { 
                    year: 'numeric', 
                    month: 'long', 
                    day: 'numeric',
                    timeZone: 'UTC' // Use UTC to prevent timezone shifts
                });
                
                // Update page title
                document.title = `${title} - Erdembayar`;
                
                // Create the post structure
                mainContent.innerHTML = `
                    <section class="hero">
                        <div class="container narrow-container">
                            <h2>${title}</h2>
                            <p>Posted on ${formattedDate}</p>
                            <div class="post-nav">
                                <a href="index.html">← Back to Home</a>
                            </div>
                        </div>
                    </section>
                    
                    <section class="content-section">
                        <div class="container narrow-container">
                            <article class="post-content">
                                <div id="post-body" class="markdown-content">
                                    <p>Loading post content...</p>
                                </div>
                            </article>
                        </div>
                    </section>
                `;
                
                // Load the markdown content from the posts folder
                return fetch(`posts/${postId}.md`);
            } else {
                // Post not found in index.json, fall back to parsing from filename
                // Extract metadata from the post ID (YYYY-MM-DD-title format)
                const parts = postId.split('-');
                
                if (parts.length >= 4) {
                    const year = parts[0];
                    const month = parts[1];
                    const day = parts[2];
                    
                    // Extract title
                    let title = parts.slice(3).join('-');
                    title = title.replace(/-/g, ' ');
                    
                    // Create a date object with UTC to prevent timezone issues
                    const dateObj = new Date(Date.UTC(parseInt(year), parseInt(month)-1, parseInt(day)));
                    const formattedDate = dateObj.toLocaleDateString('en-US', { 
                        year: 'numeric', 
                        month: 'long', 
                        day: 'numeric',
                        timeZone: 'UTC'
                    });
                    
                    // Update page title
                    document.title = `${title} - Erdembayar`;
                    
                    // Create the post structure
                    mainContent.innerHTML = `
                        <section class="hero">
                            <div class="container narrow-container">
                                <h2>${title}</h2>
                                <p>Posted on ${formattedDate}</p>
                                <div class="post-nav">
                                    <a href="index.html">← Back to Home</a>
                                </div>
                            </div>
                        </section>
                        
                        <section class="content-section">
                            <div class="container narrow-container">
                                <article class="post-content">
                                    <div id="post-body" class="markdown-content">
                                        <p>Loading post content...</p>
                                    </div>
                                </article>
                            </div>
                        </section>
                    `;
                    
                    // Load the markdown content from the posts folder
                    return fetch(`posts/${postId}.md`);
                } else {
                    throw new Error('Invalid post ID format');
                }
            }
        })
        .then(response => {
            if (!response.ok) {
                throw new Error(`File not found (status: ${response.status})`);
            }
            return response.text();
        })
        .then(markdown => {
            // Remove the first line (H1 title) to avoid duplication
            const contentWithoutTitle = markdown.split('\n').slice(1).join('\n');
            
            // Convert Markdown to HTML and insert into the page
            document.getElementById('post-body').innerHTML = marked.parse(contentWithoutTitle);
        })
        .catch(error => {
            console.error('Error loading post:', error);
            
            mainContent.innerHTML = `
                <section class="hero">
                    <div class="container narrow-container">
                        <h2>Error Loading Post</h2>
                        <div class="post-nav">
                            <a href="index.html">← Back to Home</a>
                        </div>
                    </div>
                </section>
                
                <section class="content-section">
                    <div class="container narrow-container">
                        <div class="error-message">
                            <p>Could not load the post content</p>
                            <p class="error-details">${error.message}</p>
                        </div>
                    </div>
                </section>
            `;
        });
}

// Load the blog listing page
function loadBlogPage() {
    const mainContent = document.getElementById('main-content');
    if (!mainContent) return;
    
    // Set page title
    document.title = 'Blog - Erdembayar';
    
    // Update URL without reloading the page
    history.pushState(null, '', 'index.html?page=blog');
    
    // Inject the blog page content
    mainContent.innerHTML = `
        <section class="hero">
            <div class="container narrow-container">
                <h2>Blog - Erdembayar</h2>
                <div class="post-nav">
                    <a href="index.html">← Back to Home</a>
                </div>
            </div>
        </section>

        <section class="content-section">
            <div class="container narrow-container">
                <div class="post-grid">
                    <div class="loading">Loading posts...</div>
                </div>
            </div>
        </section>
    `;
    
    // Load all blog posts
    loadBlogPosts(false);
}

// Load the footer component
function loadFooter() {
    const footerElement = document.getElementById('footer-placeholder');
    if (footerElement) {
        footerElement.innerHTML = `
        <footer>
            <div class="container narrow-container">
                <p>&copy; ${new Date().getFullYear()} <a href="https://erdembayar.github.io">Erdembayar</a>. All rights reserved.</p>
            </div>
        </footer>
        `;
    }
}

// Load blog posts
function loadBlogPosts(limitPosts = true) {
    const postGrid = document.querySelector('.post-grid');
    if (!postGrid) return;
    
    // Show loading indicator
    postGrid.innerHTML = '<div class="loading">Loading posts...</div>';
    
    // Fetch the list of posts from the server
    fetch('posts/index.json')
        .then(response => {
            if (!response.ok) {
                throw new Error(`Failed to fetch posts (status: ${response.status})`);
            }
            return response.json();
        })
        .then(posts => {
            // Ensure posts is an array
            const postsArray = Array.isArray(posts) ? posts : [];
            
            // Sort posts (newest first)
            postsArray.sort((a, b) => new Date(b.date) - new Date(a.date));
            
            // Clear loading message
            postGrid.innerHTML = '';
            
            // Limit posts on the home page if requested
            const postsToShow = limitPosts ? postsArray.slice(0, 5) : postsArray;
            
            // Create post items
            postsToShow.forEach(post => {
                const postItem = document.createElement('div');
                postItem.className = 'post-item';
                
                // Create date with correct timezone handling
                const dateParts = post.date.split('-');
                const dateObj = new Date(Date.UTC(dateParts[0], dateParts[1]-1, dateParts[2]));
                
                const formattedDate = dateObj.toLocaleDateString('en-US', { 
                    year: 'numeric', 
                    month: 'short', 
                    day: 'numeric',
                    timeZone: 'UTC'
                });
                
                postItem.innerHTML = `
                    <div class="post-date">${formattedDate}</div>
                    <h3 class="post-title"><a href="index.html?post=${post.id}">${post.title}</a></h3>
                `;
                
                postGrid.appendChild(postItem);
            });
            
            // Show message if no posts
            if (postsArray.length === 0) {
                postGrid.innerHTML = '<p>No blog posts found.</p>';
            }
        })
        .catch(error => {
            console.error('Error loading posts:', error);
            postGrid.innerHTML = `
                <div class="error-message">
                    <p>Could not load blog posts</p>
                    <p class="error-details">${error.message}</p>
                </div>
            `;
        });
}