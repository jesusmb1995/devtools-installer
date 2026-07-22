return {
  meta = {
    url = "BAD_URL_github.com/casey/just",
    description = "Format Justfile.",
  },
  command = "just",
  args = { "--fmt", "--unstable", "-f", "$FILENAME" },
  stdin = false,
}
