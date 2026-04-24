import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions";
import { setGlobalOptions } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { GoogleGenAI } from "@google/genai";

initializeApp();
setGlobalOptions({ region: "us-central1" });

const db = getFirestore();
const geminiApiKey = defineSecret("GEMINI_API_KEY");

type GenerateCharacterRequest = {
  worldId?: unknown;
  prompt?: unknown;
};

type GeneratedCharacterPayload = {
  id: string;
  worldId: string;
  name: string;
  role: string;
  description: string;
};

const characterSchema = {
  type: "object",
  properties: {
    name: {
      type: "string",
      description: "A memorable character name that fits the setting.",
    },
    role: {
      type: "string",
      description: "A short role, job, title, or archetype.",
    },
    description: {
      type: "string",
      description:
        "A 2-4 sentence character description covering personality, motivation, and story hook.",
    },
  },
  required: ["name", "role", "description"],
} as const;

export const generateCharacter = onCall(
  {
    secrets: [geminiApiKey],
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in before using AI Forge.");
    }

    const { worldId, prompt } = parseRequest(request.data as GenerateCharacterRequest);
    const worldRef = db.collection("users").doc(uid).collection("worlds").doc(worldId);
    const worldSnapshot = await worldRef.get();
    if (!worldSnapshot.exists) {
      throw new HttpsError("not-found", "World not found.");
    }

    const worldData = worldSnapshot.data() ?? {};
    const existingCharacters = await worldRef
      .collection("characters")
      .orderBy("createdAt", "desc")
      .limit(8)
      .get();

    const ai = new GoogleGenAI({ apiKey: geminiApiKey.value() });
    const generationPrompt = buildPrompt({
      worldName: readString(worldData.name),
      worldGenre: readString(worldData.genre),
      worldDescription: readString(worldData.description),
      userPrompt: prompt,
      existingCharacters: existingCharacters.docs
        .map((doc) => {
          const data = doc.data();
          const name = readString(data.name);
          const role = readString(data.role);
          if (!name) return null;
          return role ? `${name} (${role})` : name;
        })
        .filter((value): value is string => value != null),
    });

    try {
      const response = await ai.models.generateContent({
        model: "gemini-2.5-flash",
        contents: generationPrompt,
        config: {
          systemInstruction:
            "You create vivid, grounded characters for fictional worlds. Keep outputs original, concise, and immediately useful in a writer's notebook.",
          temperature: 0.9,
          responseMimeType: "application/json",
          responseJsonSchema: characterSchema,
        },
      });

      if (!response.text) {
        throw new HttpsError("internal", "Gemini returned an empty response.");
      }

      const generated = normalizeCharacter(
        JSON.parse(response.text) as Record<string, unknown>,
      );
      const characterRef = worldRef.collection("characters").doc();
      const payload: GeneratedCharacterPayload = {
        id: characterRef.id,
        worldId,
        name: generated.name,
        role: generated.role,
        description: generated.description,
      };

      await characterRef.set({
        name: payload.name,
        role: payload.role,
        description: payload.description,
        createdAt: FieldValue.serverTimestamp(),
      });

      return { character: payload };
    } catch (error) {
      logger.error("AI Forge character generation failed", error);
      if (error instanceof HttpsError) throw error;
      throw new HttpsError(
        "internal",
        "AI Forge could not generate a character right now.",
      );
    }
  },
);

function parseRequest(data: GenerateCharacterRequest): {
  worldId: string;
  prompt: string;
} {
  const worldId = requireText(data.worldId, "worldId");
  const prompt = requireText(data.prompt, "prompt");

  if (prompt.length > 500) {
    throw new HttpsError(
      "invalid-argument",
      "Prompt must be 500 characters or fewer.",
    );
  }

  return { worldId, prompt };
}

function buildPrompt(input: {
  worldName: string;
  worldGenre: string;
  worldDescription: string;
  userPrompt: string;
  existingCharacters: string[];
}): string {
  const existingBlock =
    input.existingCharacters.length === 0
      ? "No existing characters yet."
      : `Existing characters to avoid duplicating:\n- ${input.existingCharacters.join("\n- ")}`;

  return [
    "Create one original character for the following worldbuilding notebook.",
    "",
    `World name: ${input.worldName || "Untitled world"}`,
    `Genre: ${input.worldGenre || "Unspecified"}`,
    `World description: ${input.worldDescription || "No description supplied."}`,
    "",
    existingBlock,
    "",
    `User request: ${input.userPrompt}`,
    "",
    "Requirements:",
    "- Fit the world tone and genre.",
    "- Avoid repeating the existing cast.",
    "- Make the role short and scannable.",
    "- Make the description evocative but practical for a writer.",
    "- Do not mention being an AI or reference JSON in the output.",
  ].join("\n");
}

function normalizeCharacter(
  data: Record<string, unknown>,
): Omit<GeneratedCharacterPayload, "id" | "worldId"> {
  const name = sanitizeGeneratedText(data.name, 80);
  const role = sanitizeGeneratedText(data.role, 80);
  const description = sanitizeGeneratedText(data.description, 600);

  if (!name || !description) {
    throw new HttpsError(
      "internal",
      "AI Forge returned an incomplete character payload.",
    );
  }

  return { name, role, description };
}

function sanitizeGeneratedText(value: unknown, maxLength: number): string {
  const text = readString(value).replace(/\s+/g, " ").trim();
  if (text.length == 0) return "";
  return text.length <= maxLength ? text : text.slice(0, maxLength).trim();
}

function readString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function requireText(value: unknown, fieldName: string): string {
  const text = readString(value);
  if (text.length == 0) {
    throw new HttpsError(
      "invalid-argument",
      `Missing required field: ${fieldName}.`,
    );
  }
  return text;
}
