export default {
  plugins: [
    'remark-lint',
    ['remark-lint-no-undefined-references'],
    ['remark-lint-no-empty-sections'],
    ['remark-lint-no-dead-urls', {timeout: 7_000}],
    ['remark-lint-frontmatter', {type: 'yaml', marker: '-'}],
    ['./scripts/remark-rule-absolute-internal-links.js']
  ]
};
