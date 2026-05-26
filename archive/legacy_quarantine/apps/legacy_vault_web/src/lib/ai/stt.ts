export interface TranscriptionListener {
  onResult: (text: string) => void;
  onError: () => void;
  onReady: () => void;
}

export class STTService {
  private recognition: any = null;
  private listener: TranscriptionListener | null = null;

  start(listener: TranscriptionListener, lang: string = 'ko-KR') {
    const SR =
      (window as any).SpeechRecognition ||
      (window as any).webkitSpeechRecognition;
    if (!SR) {
      listener.onError();
      return;
    }
    this.recognition = new SR();
    this.recognition.continuous = true;
    this.recognition.interimResults = true;
    this.recognition.lang = lang;
    this.listener = listener;
    this.recognition.onresult = (e: any) => {
      let t = '';
      for (let i = e.resultIndex; i < e.results.length; i++) {
        t += e.results[i][0].transcript;
      }
      this.listener?.onResult(t);
    };
    this.recognition.onerror = () => this.listener?.onError();
    this.recognition.start();
    this.listener?.onReady();
  }

  stop() {
    this.recognition?.stop();
  }

  release() {
    this.recognition?.stop();
    this.recognition = null;
  }
}
