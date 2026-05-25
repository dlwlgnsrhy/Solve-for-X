export class EmbeddingService {
  async generate(text: string): Promise<Float32Array> {
    // Fallback: simple hash-based embedding (use Transforms.js in production)
    const encoder = new TextEncoder();
    const data = encoder.encode(text);
    const hash = Array.from(data).reduce(
      (a, b) => ((a << 5) - a) + b,
      0,
    ) >>> 0;
    const vec = new Float32Array(768);
    for (let i = 0; i < 768; i++) {
      vec[i] = ((hash * (i + 1)) % 10000) / 10000 - 0.5;
    }
    return vec;
  }
}
