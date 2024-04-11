<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:atom="http://www.w3.org/2005/Atom">
  <xsl:output method="html" version="1.0" encoding="UTF-8" indent="yes" />
  <xsl:template match="/">
    <html xmlns="http://www.w3.org/1999/xhtml" lang="en">
      <head>
        <title>RSS Feed preview - Earendelmir</title>
        <meta charset="utf-8" />
        <link rel="apple-touch-icon" sizes="180x180" href="/favicon/apple-touch-icon.png" />
        <link rel="icon" type="image/png" sizes="32x32" href="/favicon/favicon-32x32.png" />
        <link rel="icon" type="image/png" sizes="16x16" href="/favicon/favicon-16x16.png" />
        <link rel="manifest" href="/favicon/site.webmanifest" />
        <meta http-equiv="content-type" content="text/html; charset=utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <meta name="description" content="This is my web feed with the most recent blog posts. Subscribe by copying the URL from the address bar into your newsreader." />

        <meta property="og:title" content="RSS Feed preview - Earendelmir" />
        <meta property="twitter:title" content="RSS Feed preview - Earendelmir" />
        <meta property="og:description" content="This is my web feed with the most recent blog posts. Subscribe by copying the URL from the address bar into your newsreader." />
        <meta property="twitter:description" content="This is my web feed with the most recent blog posts. Subscribe by copying the URL from the address bar into your newsreader." />
        <meta property="og:url" content="https://earendelmir.xyz/feed.xml" />
        <meta property="twitter:card" content="summary" />

        <meta name="theme-color" content="#F8F9FA" media="(prefers-color-scheme: light)" />
        <meta name="theme-color" content="#18191A" media="(prefers-color-scheme: dark)" />
        <link rel="stylesheet" href="/style/style.css" />

        <style>
          header#banner nav a:not(:last-of-type) {
            margin-right: 1.6rem;
          }
          svg {
            fill: var(--color-text);
          }
          .feed-list {
            margin-top: 4rem;
          }
          .item .pub-date {
            font-size: smaller;
            color: var(--color-text2);
          }
          .item .title {
            display: grid;
            grid-template-columns: auto 1fr auto;
            grid-gap: 0;
          }
          .item .title a {
            text-transform: lowercase;
            width: 100%;
          }
          .item:not(:last-child) {
            margin-bottom: 2.4rem;
          }
        </style>
      </head>

      <body id="top">
        <header id="banner">
          <h1 translate="no">earendelmir</h1>
          <nav>
            <a class="navbar-item" href="/">Home</a>
            <a class="navbar-item" href="/about/">About</a>
            <a class="navbar-item" href="/archive/">Archive</a>
            <a class="navbar-item" href="/notes/">Notes</a>
            <a class="navbar-item" href="/more/">More</a>
          </nav>
        </header>

        <main>
          <article>
            <h1>
              <svg xmlns="http://www.w3.org/2000/svg" aria-label="Feed icon" height="26" width="22.75" viewBox="0 0 448 512"><path d="M128.1 416c0 35.4-28.7 64-64 64S0 451.3 0 416s28.7-64 64-64 64 28.7 64 64zm175.7 47.3c-8.4-154.6-132.2-278.6-287-287C7.7 175.8 0 183.1 0 192.3v48.1c0 8.4 6.5 15.5 14.9 16 111.8 7.3 201.5 96.7 208.8 208.8 .5 8.4 7.6 14.9 16 14.9h48.1c9.1 0 16.5-7.7 16-16.8zm144.2 .3C439.6 229.7 251.5 40.4 16.5 32 7.5 31.7 0 39 0 48v48.1c0 8.6 6.8 15.6 15.5 16 191.2 7.8 344.6 161.3 352.5 352.5 .4 8.6 7.4 15.5 16 15.5h48.1c9 0 16.3-7.5 16-16.5z"/></svg>
              <span style="text-transform: uppercase"> RSS</span> Preview
            </h1>
            <p>Subscribe by copying the URL from the address bar into your newsreader.</p>
            <p>Visit <a href="https://aboutfeeds.com">About Feeds</a> to learn more and get started with
            subscribing to your favorite websites. It’s free.</p>
            <div class="feed-list">
              <xsl:for-each select="/rss/channel/item">
                <div class="item">
                  <span class="title"><a><xsl:attribute name="href"><xsl:value-of select="link"/></xsl:attribute><xsl:value-of select="title"/></a></span>
                  <span class="pub-date">Published: <xsl:value-of select="pubDate"/></span>
                </div>
              </xsl:for-each>
            </div>
          </article>
        </main>

        <footer>
          <hr style="margin-top: 0; margin-bottom: inherit;"/>
          <p><a href="#top"><span lang="en">↑ Back to Top</span></a></p>
          <p lang="en">Follow via <a href="/feed.xml">RSS</a>. Get in touch via
            <a href="&#109;&#97;&#105;&#108;&#116;&#111;&#58;&#101;&#97;&#114;&#101;&#110;&#100;&#101;&#108;&#109;&#105;&#114;&#64;&#112;&#114;&#111;&#116;&#111;&#110;&#46;&#109;&#101;">email</a>.</p>
          <p><span translate="no">© 2023-2024 earendelmir</span></p>
        </footer>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
