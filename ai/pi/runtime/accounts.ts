import { readFile } from "node:fs/promises";

import { parseJsonWithSchema } from "@accel-os/shared/json";
import { Type } from "typebox";

import {
  parseOpenAICodexCredential,
  resolveOpenAICodexRuntimeAccountProfile,
} from "../extensions/openai-codex/auth.ts";
import {
  type AccountProfile,
  createNewAccountProfile,
  finalizeNewAccountProfile,
  findNewAccountProfile,
  listAccountProfiles,
  readActiveProfileName,
  writeActiveProfileName,
} from "./account-profiles.ts";

const authFileSchema = Type.Record(Type.String(), Type.Unknown());

export interface AccountInfo {
  id: string;
  email?: string;
  plan?: string;
  profile: AccountProfile;
  isCurrent: boolean;
  accessToken?: string;
}

export interface AccountProfilesState {
  profiles: AccountProfile[];
  activeProfileName?: string;
}

function isMissing(error: unknown): boolean {
  return error instanceof Error && "code" in error && error.code === "ENOENT";
}

export async function loadAccount(
  profile: AccountProfile,
  isCurrent: boolean,
): Promise<AccountInfo> {
  const raw = await readFile(profile.authPath, "utf8");
  const parsed = parseJsonWithSchema(raw, authFileSchema, profile.authPath);
  const credential = parseOpenAICodexCredential(parsed["openai-codex"]);
  if (credential === null) {
    throw new Error(`missing openai-codex OAuth credential in ${profile.authPath}`);
  }

  const account = resolveOpenAICodexRuntimeAccountProfile(credential, credential.access);
  const id = account.accountId;
  if (id === undefined || id.length === 0) {
    throw new Error(`missing openai-codex.accountId in ${profile.authPath}`);
  }

  const info: AccountInfo = {
    id,
    profile,
    isCurrent,
  };
  if (account.email !== undefined) {
    info.email = account.email;
  }
  if (account.plan !== undefined) {
    info.plan = account.plan;
  }
  if (credential.access !== undefined && credential.access.length > 0) {
    info.accessToken = credential.access;
  }
  return info;
}

export async function reconcileAccountProfiles(configDir: string): Promise<AccountProfilesState> {
  let activeProfileName = await readActiveProfileName(configDir);
  const pending = await findNewAccountProfile(configDir);
  if (pending !== undefined) {
    try {
      const pendingAccount = await loadAccount(pending, false);
      const finalized = await finalizeNewAccountProfile(configDir, pendingAccount.id);
      if (finalized !== undefined && activeProfileName === pending.name) {
        activeProfileName = finalized.name;
        await writeActiveProfileName(configDir, activeProfileName);
      }
    } catch (error: unknown) {
      if (!isMissing(error)) {
        throw error;
      }
    }
  }

  const profiles = await listAccountProfiles(configDir);
  if (
    activeProfileName !== undefined &&
    !profiles.some((profile) => profile.name === activeProfileName)
  ) {
    activeProfileName = undefined;
  }
  if (activeProfileName === undefined && profiles.length === 1) {
    const profile = profiles[0];
    if (profile !== undefined) {
      activeProfileName = profile.name;
      await writeActiveProfileName(configDir, activeProfileName);
    }
  }

  return activeProfileName === undefined ? { profiles } : { profiles, activeProfileName };
}

export async function resolveAccountProfile(configDir: string): Promise<AccountProfile> {
  const { profiles, activeProfileName } = await reconcileAccountProfiles(configDir);
  const active = profiles.find((profile) => profile.name === activeProfileName);
  if (active !== undefined) {
    return active;
  }
  if (profiles.length === 0) {
    const profile = await createNewAccountProfile(configDir);
    await writeActiveProfileName(configDir, profile.name);
    return profile;
  }
  throw new Error("multiple account profiles exist; run `ai account` to select one");
}
