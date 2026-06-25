const { clsx } = require('c:/Users/HP/Desktop/marketer/admin/node_modules/clsx');
const { twMerge } = require('c:/Users/HP/Desktop/marketer/admin/node_modules/tailwind-merge');

function cn(...inputs) {
  return twMerge(clsx(inputs));
}

const isMobileMenuOpen = false;

// Test the new mobile-only media query classes
const classes = cn(
  "w-64 bg-surface border-e border-border h-screen flex flex-col justify-between",
  "fixed inset-y-0 start-0 z-50 transform transition-transform duration-200 ease-out md:sticky md:top-0 md:z-auto md:flex",
  isMobileMenuOpen ? "translate-x-0" : "max-md:-translate-x-full max-md:rtl:translate-x-full"
);

console.log("New output:", classes);
