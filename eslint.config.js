import js from '@eslint/js';
import globals from 'globals';

export default [
  {
    // app/ is the Flutter project; it has its own analyzer (flutter analyze).
    ignores: ['dist/', 'node_modules/', 'docs/', 'app/']
  },
  js.configs.recommended,
  {
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: 'module',
      globals: {
        ...globals.browser
      }
    },
    rules: {
      'no-unused-vars': ['error', { args: 'none' }]
    }
  }
];
