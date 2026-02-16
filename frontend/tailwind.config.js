/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        medical: {
          dark: '#0a0e27',
          darker: '#050814',
          blue: '#1e40af',
          accent: '#3b82f6'
        }
      }
    },
  },
  plugins: [],
}
