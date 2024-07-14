#let project(
  title: "",
  subtitle: "",
  author: "",
  additionalInfo: "",
  date: none,
  body,
) = {
  // Set the document's basic properties.
  set document(author: author, title: title)
  set page(footer: [
    #h(1fr)
    #counter(page).display("1/1", both: true)
  ])
  set text(font: "Linux Libertine", lang: "en")
  set heading(numbering: "1.1")
  show heading: set block(above: 1.4em, below: 1em)
  show bibliography: set heading(numbering: "1.1")
  set bibliography(title: "References", style: "harvard-cite-them-right")
  set raw(tab-size: 4)  
  show link: underline

  // Title page.
  set align(center)
  v(1fr)
  text(18pt, author)
  linebreak()
  text(14pt, strong(additionalInfo))
  v(2em)

  text(14pt, "BACHELOR OF SCIENCE")
  linebreak()
  text(18pt, "Game Programming")
  v(2em)
  
  rect(width: 100%, [
    #text(2em, weight: 700, title)
    #v(-1em)
    #text(1.5em, weight: 700, subtitle)
  ])

  v(4em)

  text(12pt, "SUMMATIVE - 6FSC0XF101 - GPR921")
  linebreak()
  text(12pt, "SIORAK Nicolas - FARHAN Elias")
  v(2fr)
  text(1.1em, date)
  linebreak()
  //[#recursive_count(body) words]
  
  v(1fr)

  set align(start + top)
  pagebreak()

  // Table of contents.
  outline(depth: 3, indent: true, title: "Table of Contents")
  pagebreak()


  // Main body.
  set par(justify: true)

  body
}