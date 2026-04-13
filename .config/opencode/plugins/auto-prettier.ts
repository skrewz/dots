export const AutoFormat: Plugin = async ({ $ }) => {
  return {
    tool: {
      execute: {
        after: async (input, output) => {
          // This runs AFTER the tool completes
          if (input.tool === "edit") {
            await $`prettier --write ${output.args.filePath}`
            console.log("✨ Code formatted!")
          }
        }
      }
    }
  }
}
