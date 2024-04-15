function setTheme(theme, save=false, noauto=true) {
  if (theme === "dark") {
    document.documentElement.classList.add("dark")
    document.documentElement.classList.remove("light")
    if (noauto) document.documentElement.classList.remove("auto")
    if (save) localStorage.setItem("theme", theme)
  } else if (theme === "light") {
    document.documentElement.classList.add("light")
    document.documentElement.classList.remove("dark")
    if (noauto) document.documentElement.classList.remove("auto")
    if (save) localStorage.setItem("theme", theme)
  } else if (theme === "auto") {
    document.documentElement.classList.add("auto")
    document.documentElement.classList.remove("light")
    document.documentElement.classList.remove("dark")
    localStorage.removeItem("theme")
    setTheme(q.matches ? "dark" : "light", false, false)
  } else return
  try {
    document.querySelector('meta[name="theme-color"]').setAttribute("content", theme === "dark" ? "#18191A" : "#F8F9FA")
    if (save) setText(theme)
  }
  catch {}
}
function setText(theme){document.getElementById("btn-theme").innerText=theme}

const q = window.matchMedia("(prefers-color-scheme: dark)")
const initialTheme = localStorage.getItem("theme") || "auto"
setTheme(initialTheme, true, false)

window.onload = function(){
  setText(initialTheme)
  q.addEventListener("change", function(){
    if (!("theme" in localStorage)) setTheme(q.matches ? "dark" : "light", false, false)
  });
  document.getElementById("btn-theme").addEventListener("click", function(){
    classes=document.documentElement.classList;
    if (classes.contains("auto")) newTheme="dark"
    else if (classes.contains("dark")) newTheme="light"
    else if (classes.contains("light")) newTheme="auto"
    setTheme(newTheme, true, newTheme !== "auto")
  });
};
