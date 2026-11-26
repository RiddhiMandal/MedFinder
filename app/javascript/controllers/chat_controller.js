import { Controller } from "@hotwired/stimulus"

// Small chat behaviours: Enter to send, example-question buttons,
// clearing the box after sending, and keeping the newest step in view.
export default class extends Controller {
  static targets = ["messages", "form", "input"]

  connect() {
    this.scrollToBottom()
    this.observer = new MutationObserver(() => this.scrollToBottom())
    this.observer.observe(this.messagesTarget, { childList: true, subtree: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  submit(event) {
    if (event.shiftKey) return
    event.preventDefault()
    if (this.inputTarget.value.trim()) this.formTarget.requestSubmit()
  }

  ask(event) {
    this.inputTarget.value = event.currentTarget.dataset.question
    this.formTarget.requestSubmit()
  }

  reset(event) {
    if (event.detail.success) this.formTarget.reset()
  }

  scrollToBottom() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }
}
