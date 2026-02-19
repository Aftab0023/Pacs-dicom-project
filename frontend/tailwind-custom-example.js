/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // OPTION 1: Modern Blue Theme
        medical: {
          dark: '#1e293b',      // Slate-800
          darker: '#0f172a',    // Slate-900
          blue: '#0ea5e9',      // Sky-500
          accent: '#06b6d4'     // Cyan-500
        },
        
        // OPTION 2: Green Medical Theme
        // medical: {
        //   dark: '#064e3b',      // Emerald-900
        //   darker: '#022c22',    // Emerald-950
        //   blue: '#10b981',      // Emerald-500
        //   accent: '#34d399'     // Emerald-400
        // },
        
        // OPTION 3: Purple Professional Theme
        // medical: {
        //   dark: '#581c87',      // Purple-900
        //   darker: '#3b0764',    // Purple-950
        //   blue: '#8b5cf6',      // Violet-500
        //   accent: '#a855f7'     // Purple-500
        // },
        
        // OPTION 4: Custom Brand Colors
        // medical: {
        //   dark: '#2d3748',      // Your brand dark
        //   darker: '#1a202c',    // Your brand darker
        //   blue: '#4299e1',      // Your brand primary
        //   accent: '#63b3ed'     // Your brand accent
        // }
      },
      
      // Add custom fonts
      fontFamily: {
        'medical': ['Inter', 'system-ui', 'sans-serif'],
        'mono': ['JetBrains Mono', 'monospace']
      },
      
      // Add custom spacing
      spacing: {
        '18': '4.5rem',
        '88': '22rem'
      },
      
      // Add custom animations
      animation: {
        'fade-in': 'fadeIn 0.5s ease-in-out',
        'slide-up': 'slideUp 0.3s ease-out'
      },
      
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' }
        },
        slideUp: {
          '0%': { transform: 'translateY(10px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' }
        }
      }
    },
  },
  plugins: [],
}