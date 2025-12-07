const copyHandlers = () => {
  document.querySelectorAll("[data-copy-target]").forEach((btn) => {
    btn.addEventListener("click", (e) => {
      e.preventDefault()
      const targetSelector = btn.dataset.copyTarget
      const messageSelector = btn.dataset.copyMessage
      const targetEl = document.querySelector(targetSelector)
      if (!targetEl) return
      const value = targetEl.value || targetEl.textContent || ""
      if (!value) return

      navigator.clipboard && navigator.clipboard.writeText(value)

      if (messageSelector) {
        const msgEl = document.querySelector(messageSelector)
        if (msgEl) {
          msgEl.classList.remove("hidden")
          msgEl.textContent = "Copied!"
          setTimeout(() => {
            msgEl.classList.add("hidden")
          }, 1500)
        }
      }
    })
  })
}

document.addEventListener("turbo:load", copyHandlers)
