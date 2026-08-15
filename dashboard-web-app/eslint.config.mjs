const eslintConfig = [
  {
    ignores: [
      "**/node_modules/**",
      "**/.next/**",
      "**/out/**",
      "**/build/**",
      "**/next-env.d.ts",
      "**/examples/**",
      "**/skills/**"
    ]
  },
  {
    files: ["src/**/*.{ts,tsx,js,jsx}"],
    rules: {
      "no-unused-vars": "off",
      "no-console": "off",
      "no-empty": "off",
      "no-undef": "off",
      "prefer-const": "off"
    }
  }
];

export default eslintConfig;
