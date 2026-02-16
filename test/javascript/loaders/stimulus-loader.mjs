import { pathToFileURL } from "node:url"
import path from "node:path"

const stimulusMockUrl = pathToFileURL(
  path.resolve("test/javascript/mocks/stimulus.mjs")
).href

export async function resolve(specifier, context, defaultResolve) {
  if (specifier === "@hotwired/stimulus") {
    return { url: stimulusMockUrl, shortCircuit: true }
  }

  if (specifier.startsWith("lib/")) {
    const resolved = pathToFileURL(
      path.resolve("app/javascript", specifier + ".js")
    ).href
    return { url: resolved, shortCircuit: true }
  }

  return defaultResolve(specifier, context, defaultResolve)
}
