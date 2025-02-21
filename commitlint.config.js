module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'subject-case': [2, 'always', ['sentence-case', 'lower-case']], // Allow sentence case
    'type-empty': [2, 'never'], // Type must be present
    'subject-empty': [2, 'never'], // Subject must be present
  },
  ignores: [(message) => message.startsWith('Merge ')], // Ignore merge commits
};
