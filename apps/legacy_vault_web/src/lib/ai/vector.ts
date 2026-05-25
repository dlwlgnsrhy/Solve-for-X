import { db } from '@/lib/db';

export async function insertVector(
  table: string,
  embedding: Float32Array,
  refId: string,
): Promise<string> {
  const id = crypto.randomUUID();
  await (db as any)[table].put({ id, embedding, [refId]: refId });
  return id;
}

export async function searchNearest(
  embedding: Float32Array,
  table: string,
  limit: number = 5,
): Promise<Array<{ id: string; distance: number }>> {
  const records = await (db as any)[table].toArray();
  const results = records
    .map((r: any) => ({ ...r, distance: cosineDistance(embedding, r.embedding) }))
    .sort((a: { distance: number }, b: { distance: number }) => a.distance - b.distance)
    .slice(0, limit);
  return results as any;
}

function cosineDistance(a: Float32Array, b: Float32Array): number {
  let dot = 0;
  let magA = 0;
  let magB = 0;
  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    magA += a[i] * a[i];
    magB += b[i] * b[i];
  }
  return dot / ((Math.sqrt(magA) * Math.sqrt(magB)) || 1);
}
