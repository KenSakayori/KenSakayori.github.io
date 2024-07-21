// Sets 'light-theme' or 'dark-theme' as a class name for <body>
let element = document.querySelector('body');
if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches)
  element.className = 'dark-theme';
else
  element.className = 'light-theme';
