export interface LauncherArgs {
  passthrough: string[];
  showHelp: boolean;
  useAccountSwitcher: boolean;
}

export function parseLauncherArgs(args: readonly string[]): LauncherArgs {
  let showHelp = false;
  let useAccountSwitcher = false;
  let modifierCount = 0;

  for (const arg of args) {
    if (arg === "help") {
      showHelp = true;
    } else if (arg === "account") {
      useAccountSwitcher = true;
    } else {
      break;
    }
    modifierCount += 1;
  }

  return {
    passthrough: args.slice(modifierCount),
    showHelp,
    useAccountSwitcher,
  };
}
