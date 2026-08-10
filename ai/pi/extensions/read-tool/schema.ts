import { Type, type Static } from "typebox";

export const readTargetSchema = Type.Object(
  {
    path: Type.String({ description: "Path to a file or directory, relative or absolute" }),
    offset: Type.Optional(
      Type.Integer({
        minimum: 1,
        description: "File line number to start reading from (1-indexed)",
      }),
    ),
    limit: Type.Optional(
      Type.Integer({ minimum: 1, description: "Maximum number of file lines to read" }),
    ),
  },
  { additionalProperties: false },
);

export const readToolSchema = Type.Object(
  {
    targets: Type.Array(readTargetSchema, {
      minItems: 1,
      maxItems: 20,
      description: "Files and directories to read in the requested order",
    }),
    recursive: Type.Optional(
      Type.Boolean({ description: "Recursively list directory contents. Defaults to false." }),
    ),
    max_depth: Type.Optional(
      Type.Integer({
        minimum: 1,
        maximum: 20,
        description: "Maximum directory depth when recursive=true. Defaults to 4.",
      }),
    ),
    show_line_numbers: Type.Optional(
      Type.Boolean({
        description: "Prefix returned text-file lines with their original line numbers",
      }),
    ),
  },
  { additionalProperties: false },
);

export type ReadTargetInput = Static<typeof readTargetSchema>;
export type ReadToolInput = Static<typeof readToolSchema>;
