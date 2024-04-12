function setTheme(dark, save=false) {
  if (dark) document.documentElement.classList.add("dark")
  else document.documentElement.classList.remove("dark")
  if (save) localStorage.setItem("theme", dark ? "dark" : "light")
  try {
    setText(dark)
    document.querySelector('meta[name="theme-color"]').setAttribute("content", dark ? "#18191A" : "#F8F9FA")
  }
  catch {}
}
function setText(dark) {
  document.getElementById("btn-theme").innerText = dark ? "Light" : "Dark"
}

const q = window.matchMedia("(prefers-color-scheme: dark)")
const initialDark = localStorage.getItem("theme") === "dark" || (!("theme" in localStorage) && q.matches)
setTheme(initialDark)

window.onload = function(){
  setText(initialDark)
  q.addEventListener("change", function(){
    if (!("theme" in localStorage))
      setTheme(q.matches)
  });
  document.getElementById("btn-theme").addEventListener("click", function(){
    setTheme(!document.documentElement.classList.contains("dark"), true)
  });
};
