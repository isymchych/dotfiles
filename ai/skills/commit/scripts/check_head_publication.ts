import { runGit } from "../../lib/git_command.ts";

if (process.argv.length > 2) usage();

const head = await runGit(["rev-parse", "HEAD"]);
if (!head.success) fail(head.stderr || head.stdout || `git exited with status ${head.code}`);

const refs = await runGit([
  "for-each-ref",
  "--format=%(refname:short)",
  "--contains=HEAD",
  "refs/remotes",
]);
if (!refs.success) fail(refs.stderr || refs.stdout || `git exited with status ${refs.code}`);

const sha = head.stdout.trim();
if (!sha) fail("git rev-parse returned empty commit sha");

const remoteRefs = refs.stdout.split(/\r?\n/).filter(Boolean);
console.log(`HEAD ${sha}`);
for (const ref of remoteRefs) console.log(`PUBLISHED ${ref}`);
if (remoteRefs.length === 0) console.log("UNPUBLISHED");

function fail(message: string): never {
  const code = /not a git repository/i.test(message) ? "ERR_NOT_REPO" : "ERR_GIT";
  console.error(`${code}: ${message}`);
  process.exit(code === "ERR_NOT_REPO" ? 65 : 66);
}

function usage(): never {
  console.error("ERR_USAGE: expected no args");
  process.exit(64);
}
