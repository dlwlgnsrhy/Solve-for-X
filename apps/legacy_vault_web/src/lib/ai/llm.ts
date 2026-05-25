export class LLMService {
  private engine: any = null;

  async init(
    modelId: string = 'Llama-3.2-3B-Instruct-q4f16_1-MLC',
  ): Promise<boolean> {
    try {
      const webllm = await import('@mlc-ai/web-llm');
      this.engine = await webllm.CreateMLCEngine(modelId, {
        initProgressCallback: () => {},
      });
      return true;
    } catch {
      return false;
    }
  }

  async generate(prompt: string): Promise<string> {
    if (!this.engine) return 'LLM not initialized';
    try {
      const results = await this.engine.chat.completions.create({
        messages: [{ role: 'user', content: prompt }],
        max_tokens: 512,
        temperature: 0.7,
      });
      return results.choices[0]?.message?.content || '';
    } catch {
      return 'Error generating response';
    }
  }

  release() {
    this.engine?.dispose();
    this.engine = null;
  }
}
