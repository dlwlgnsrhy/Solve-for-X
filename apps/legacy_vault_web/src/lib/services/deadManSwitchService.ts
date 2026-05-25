export class DeadManSwitchService {
  private heartbeatId: number | null = null;
  private lastPing = Date.now();
  private deadline = Date.now() + 7 * 24 * 60 * 60 * 1000;

  start(days: number = 7) {
    this.deadline = Date.now() + days * 24 * 60 * 60 * 1000;
    this.ping();
    this.heartbeatId = setInterval(() => this.ping(), 60 * 60 * 1000) as any;
  }

  stop() {
    if (this.heartbeatId) clearInterval(this.heartbeatId as any);
  }

  ping() {
    this.lastPing = Date.now();
  }

  getStatus() {
    return {
      lastPing: this.lastPing,
      deadline: this.deadline,
      expired: Date.now() > this.deadline,
    };
  }
}
