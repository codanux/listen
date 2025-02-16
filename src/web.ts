import { WebPlugin } from '@capacitor/core';

import type { ListenPlugin } from './definitions';

export class ListenWeb extends WebPlugin implements ListenPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
