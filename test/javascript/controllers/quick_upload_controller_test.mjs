import test from "node:test"
import assert from "node:assert/strict"

import QuickUploadController, {
  UPLOAD_CONFIG,
  formatFileSize
} from "../../../app/javascript/controllers/quick_upload_controller.js"

// --- Config ---
test("UPLOAD_CONFIG exports max file size and accepted types", () => {
  assert.ok(typeof UPLOAD_CONFIG.MAX_FILE_SIZE === "number")
  assert.ok(UPLOAD_CONFIG.MAX_FILE_SIZE > 0)
  assert.ok(Array.isArray(UPLOAD_CONFIG.ACCEPTED_TYPES))
  assert.ok(UPLOAD_CONFIG.ACCEPTED_TYPES.length > 0)
})

// --- formatFileSize ---
test("formatFileSize formats bytes to human readable", () => {
  assert.equal(formatFileSize(0), "0 B")
  assert.equal(formatFileSize(1023), "1023 B")
  assert.equal(formatFileSize(1024), "1.0 KB")
  assert.equal(formatFileSize(1048576), "1.0 MB")
})

// --- Controller ---
test("controller declares correct targets", () => {
  assert.ok(QuickUploadController.targets)
  assert.ok(QuickUploadController.targets.includes("sheet"))
  assert.ok(QuickUploadController.targets.includes("fileInput"))
  assert.ok(QuickUploadController.targets.includes("fileInfo"))
})
