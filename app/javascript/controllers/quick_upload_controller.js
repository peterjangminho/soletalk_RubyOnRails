import { Controller } from "@hotwired/stimulus"

export const UPLOAD_CONFIG = Object.freeze({
  MAX_FILE_SIZE: 10 * 1024 * 1024,
  ACCEPTED_TYPES: [
    "text/plain",
    "application/pdf",
    "text/csv",
    "application/json",
    "text/markdown"
  ]
})

export function formatFileSize(bytes) {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1048576) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / 1048576).toFixed(1)} MB`
}

export default class extends Controller {
  static targets = ["fileInput", "sheet", "fileInfo"]
  static values = { url: String }

  openFilePicker(event) {
    event.preventDefault()
    if (this.hasFileInputTarget) this.fileInputTarget.click()
  }

  fileSelected() {
    const file = this.fileInputTarget.files[0]
    if (!file) return

    if (this.hasFileInfoTarget) {
      this.fileInfoTarget.textContent = `${file.name} (${formatFileSize(file.size)})`
    }

    if (this.hasSheetTarget) {
      this.sheetTarget.hidden = false
    }
  }

  confirm() {
    const file = this.fileInputTarget.files[0]
    if (!file) return

    const formData = new FormData()
    formData.append("file", file)

    fetch(this.urlValue, {
      method: "POST",
      body: formData,
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
      }
    }).then(response => {
      if (response.ok) {
        this.closeSheet()
      }
    })
  }

  cancel() {
    this.fileInputTarget.value = ""
    this.closeSheet()
  }

  closeSheet() {
    if (this.hasSheetTarget) this.sheetTarget.hidden = true
  }
}
