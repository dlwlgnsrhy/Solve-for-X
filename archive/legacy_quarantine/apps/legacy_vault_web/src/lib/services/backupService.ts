import JSZip from 'jszip';

export async function exportData(
  data: Record<string, any>,
): Promise<Blob> {
  const zip = new JSZip();
  Object.entries(data).forEach(([key, value]) => {
    zip.file(`${key}.json`, JSON.stringify(value, null, 2));
  });
  return await zip.generateAsync({ type: 'blob' });
}
