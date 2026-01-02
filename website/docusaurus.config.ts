import { themes as prismThemes } from 'prism-react-renderer';
import type { Config } from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

const config: Config = {
  title: 'Homelab',
  tagline: 'My kubernetes homelab',
  favicon: 'img/favicon.ico',

  // Set the production url of your site here
  url: 'https://homelab.orkestack.com', // Or your real site URL
  baseUrl: '/',

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: 'theepicsaxguy', // Usually your GitHub org/user name.
  projectName: 'homelab', // Usually your repo name.

  onBrokenLinks: 'throw',
  markdown: {
    hooks: {
      onBrokenMarkdownLinks: 'throw',
    },
  },

  // Even if you don't use internationalization, you can use this field to set
  // useful metadata like html lang. For example, if your site is Chinese, you
  // may want to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: 'sidebars.ts',
          editUrl: 'https://github.com/theepicsaxguy/homelab/edit/main/website/',
          exclude: ['styles/**'],
        },
        theme: {
          customCss: './src/css/custom.css',
        },
        blog: false,
        sitemap: {
          changefreq: 'weekly',
          priority: 0.5,
          ignorePatterns: ['/tags/**'],
          filename: 'sitemap.xml',
        },
      } satisfies Preset.Options,
    ],
  ],
  themes: [
    [
      require.resolve('@easyops-cn/docusaurus-search-local'),
      {
        hashed: true,
        docsRouteBasePath: 'docs',
        highlightSearchTermsOnTargetPage: true,
      },
    ],
  ],

  themeConfig: {
    // Replace with your project's social card
    colorMode: {
      defaultMode: 'dark',
      disableSwitch: false,
      respectPrefersColorScheme: false,
    },
    metadata: [
      { name: 'keywords', content: 'kubernetes, homelab' },
      { name: 'twitter:card', content: 'summary_large_image' },
    ],
    image: 'img/logo.png',
    navbar: {
      title: 'Homelab',
      logo: {
        alt: 'Homelab Logo',
        src: 'img/logo.png',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'DocumentationSidebar',
          position: 'left',
          label: 'Documentation',
        },
        {
          href: 'https://github.com/theepicsaxguy/homelab',
          label: 'GitHub',
          position: 'right',
        },
        {
          href: 'https://goingdark.social/',
          label: 'Mastodon',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Docs',
          items: [
            {
              label: 'Intro',
              to: '/docs/intro',
            },
          ],
        },
        {
          title: 'More',
          items: [
            {
              label: 'GitHub',
              href: 'https://github.com/theepicsaxguy/homelab',
            },
            {
              label: 'Mastodon',
              href: 'https://goingdark.social/',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} theepicsaxguy. Built with Docusaurus.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
