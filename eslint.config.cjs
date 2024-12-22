const { fixupConfigRules, fixupPluginRules } = require('@eslint/compat');

const editorconfig = require('eslint-plugin-editorconfig');
const _import = require('eslint-plugin-import');
const globals = require('globals');
const js = require('@eslint/js');

const { FlatCompat } = require('@eslint/eslintrc');

const compat = new FlatCompat({
	baseDirectory: __dirname,
	recommendedConfig: js.configs.recommended,
	allConfig: js.configs.all,
});

module.exports = [
	{
		ignores: [
			'**/*.cjs',
			'**/*.min.js',
			'**/node_modules/',
			'**/vendor/',
			'**/.vitepress/dist/',
			'!docs/.vitepress/',
			'docs/.vitepress/cache/',
		],
	},
	...fixupConfigRules(
		compat.extends(
			'eslint:recommended',
			'plugin:editorconfig/noconflict',
			'plugin:import/recommended',
			'prettier',
		),
	),
	{
		plugins: {
			editorconfig: fixupPluginRules(editorconfig),
			import: fixupPluginRules(_import),
		},

		languageOptions: {
			globals: {
				...globals.browser,
				Alpine: 'readonly',
			},

			ecmaVersion: 'latest',
			sourceType: 'module',
		},

		rules: {
			'no-unused-vars': [
				'error',
				{
					argsIgnorePattern: '^_',
					varsIgnorePattern: '^_',
					caughtErrorsIgnorePattern: '^_',
				},
			],

			'import/order': [
				'error',
				{
					groups: [
						'builtin',
						'external',
						'internal',
						'parent',
						'sibling',
						'index',
						'object',
						'type',
					],
				},
			],

			'no-console': 'error',
			'prefer-const': 'error',
			'import/no-unresolved': 'off',
		},
	},
];
