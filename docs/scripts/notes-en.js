function filterLang(checkbox) {
  var posts = document.getElementsByClassName("h-entry")
  localStorage.setItem("eng-only", checkbox.checked)
  if (checkbox.checked)
    for (post of posts)
      if (post.getElementsByTagName("p")[0].lang == "it")
        post.style.display = "none"
      else
        post.style.display = ""
  else
    for (post of posts)
      post.style.display = ""
}
var checkbox = document.getElementById("eng-only-checkbox")
if (localStorage.getItem("eng-only") === "true")
  checkbox.checked = true
else
  checkbox.checked = false
filterLang(checkbox)
