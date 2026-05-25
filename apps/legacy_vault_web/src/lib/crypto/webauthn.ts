export async function registerPasskey(name: string): Promise<boolean> {
  try {
    await navigator.credentials.create({
      publicKey: {
        challenge: new TextEncoder().encode('mock-challenge'),
        rp: { name: 'Legacy Vault' },
        user: {
          id: new TextEncoder().encode(name),
          name,
          displayName: name,
        },
        pubKeyCredParams: [{ alg: -7, type: 'public-key' }],
        authenticatorSelection: { authenticatorAttachment: 'platform' },
      },
    } as any);
    return true;
  } catch {
    return false;
  }
}

export async function getPasskey(): Promise<any> {
  return navigator.credentials.get({
    publicKey: { rpId: location.host },
  } as any);
}
