// Adapted from OpenAI Codex's apply_patch grammar; see ./UPSTREAM.md.
// Keep this aligned with parser.ts, which remains the runtime source of truth.
export const APPLY_PATCH_LARK_GRAMMAR = String.raw`start: begin_patch hunk+ end_patch
begin_patch: "*** Begin Patch" LF
end_patch: "*** End Patch" LF?

hunk: add_hunk | delete_hunk | update_hunk
add_hunk: "*** Add File: " filename LF add_line+
delete_hunk: "*** Delete File: " filename LF
update_hunk: "*** Update File: " filename LF change_move? change

filename: /(.+)/
add_line: "+" /(.*)/ LF -> line

change_move: "*** Move to: " filename LF
change: initial_change (eof_line blank_line* following_change)* eof_line? blank_line*
initial_change: change_context? change_line+ (change_context change_line+)*
following_change: change_context change_line+ (change_context change_line+)*
change_context: ("@@" | "@@ " /(.+)/) LF
change_line: ("+" | "-" | " ") /(.*)/ LF | blank_line
eof_line: "*** End of File" LF
blank_line: LF

%import common.LF
`;
