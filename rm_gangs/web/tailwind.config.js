/** @type {import('tailwindcss').Config} */

export default {
	content: ['./index.html', './src/**/*.{svelte,js,ts,jsx,tsx}'],
	theme: {
		extend: {
			colors: {
				primary: '#1e272b',
				secondary: '#424050',
				accent: '#f15d38',

				'txt-primary': '#faf7ff',
				'txt-secondary': '#2b2b2b',
			},
		},
	},
	plugins: [],
};
