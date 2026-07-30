// Adapted from OpenAI Codex's apply_patch Lark grammar.
// Keep this aligned with parser.ts: parser.ts remains the runtime source of truth.
export const APPLY_PATCH_LARK_GRAMMAR = String.raw`start: begin_patch separator* hunk (separator* hunk)* separator* end_patch
begin_patch: "*** Begin Patch" LF
end_patch: "*** End Patch" LF?

hunk: add_hunk | delete_hunk | update_hunk
add_hunk: "*** Add File: " filename LF add_line*
delete_hunk: "*** Delete File: " filename LF
update_hunk: "*** Update File: " filename LF separator* ((change_move separator* change?) | change)

filename: /(.+)/
separator: LF
add_line: "+" /(.*)/ LF -> line

change_move: "*** Move to: " filename LF
change: (change_context | change_line)+ eof_line?
change_context: ("@@" | "@@ " /(.+)/) LF
change_line: ("+" | "-" | " ") /(.*)/ LF
eof_line: "*** End of File" LF

%import common.LF
`;
