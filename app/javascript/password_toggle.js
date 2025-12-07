document.addEventListener("turbo:load", () => {
  document.querySelectorAll("[data-toggle-password]").forEach((btn) => {
    btn.addEventListener("click", () => {
      const input = document.querySelector(btn.dataset.togglePassword)
      if (!input) return
      const isHidden = input.type === "password"
      input.type = isHidden ? "text" : "password"
      btn.textContent = isHidden ? "Hide" : "Show"
    })
  })
})
