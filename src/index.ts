import { registerPlugin } from '@capacitor/core';

import type { ListenPlugin } from './definitions';

const Listen = registerPlugin<ListenPlugin>('Listen', {
  web: () => import('./web').then((m) => new m.ListenWeb()),
});

export * from './definitions';
export { Listen };
